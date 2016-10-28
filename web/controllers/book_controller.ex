defmodule Bookish.BookController do
  use Bookish.Web, :controller
  
  plug Bookish.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]

  alias Bookish.Book
  alias Bookish.Circulation
  alias Bookish.Tagging
  alias Bookish.Location

  @entries_per_page 10 

  def index(conn, _params) do
    conn
    |> redirect(to: book_path(conn, :paginate, 1))
  end

  def paginate(conn, %{"number" => number}) do
    n = String.to_integer(number)
    books = 
      Book.sorted_by_title 
      |> Book.paginate(n, @entries_per_page)
      |> load_from_query 
    render(conn, "index.html", books: books, page_count: number_of_pages, current_page: n)
  end

  defp number_of_pages do
    count = 
      Book
      |> Book.count
      |> Repo.all
      |> List.first
    Float.ceil(count / @entries_per_page)
    |> Kernel.trunc
  end

  def index_by_letter(conn, %{"letter" => letter}) do
    books = 
      Book.get_by_letter(letter)
      |> load_from_query 
    render(conn, "index.html", books: books, page_count: number_of_pages, current_page: 1)
  end

  def new(conn, _params) do
    changeset = Book.changeset(%Book{}) 
    render(conn, "new.html", changeset: changeset, locations: get_locations)
  end

  def create(conn, %{"book" => book_params}) do
    changeset = Book.changeset(%Book{}, book_params)

    case Repo.insert(changeset) do
      {:ok, book} ->
        Tagging.update_tags(book, book.tags_list)
        conn
        |> put_flash(:info, "Book created successfully.")
        |> redirect(to: book_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, locations: get_locations)
    end
  end

  def edit(conn, %{"id" => id}) do
    book = 
      Repo.get!(Book, id) 
      |> preload_associations
      |> Tagging.set_tags_list
    changeset = Book.changeset(book)
    render(conn, "edit.html", book: book, changeset: changeset, locations: get_locations)
  end

  def update(conn, %{"id" => id, "book" => book_params}) do
    book = 
      Repo.get!(Book, id) 
      |> Repo.preload(:location)
    changeset = Book.changeset(book, book_params)

    case Repo.update(changeset) do
      {:ok, book} ->
        Tagging.update_tags(book, book.tags_list)
        conn
        |> put_flash(:info, "Book updated successfully.")
        |> redirect(to: book_path(conn, :index))
      {:error, changeset} ->
        render(conn, "edit.html", book: book, changeset: changeset, locations: get_locations)
    end
  end

  def delete(conn, %{"id" => id}) do
    book = Repo.get!(Book, id)
    Repo.delete!(book)

    conn
    |> put_flash(:info, "Book deleted successfully.")
    |> redirect(to: book_path(conn, :index))
  end

  defp load_from_query(query) do
    query
    |> Repo.all
    |> preload_associations
    |> Circulation.set_virtual_attributes 
  end

  defp preload_associations(coll) do
    coll
    |> Repo.preload(:tags)
    |> Repo.preload(:location)
  end

  defp get_locations do
    Location.select_name 
    |> Repo.all
  end
end
