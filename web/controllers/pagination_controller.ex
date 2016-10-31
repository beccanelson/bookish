defmodule Bookish.PaginationController do
  use Bookish.Web, :controller

  alias Bookish.Resource
  alias Bookish.BookController
  alias Bookish.Book

  @entries_per_page 10
  
  def paginate(conn, params) do
    case params do
      %{"number" => "1"} ->
        redirect(conn, to: book_path(conn, :index))
      %{"number" => _ } ->
        show_pages(conn, params)
    end
  end
  
  def show_pages(conn, %{"number" => number}) do
    n = String.to_integer(number)
    resources = 
      Book
      |> Resource.sorted_by_title
      |> Resource.paginate(n, @entries_per_page)
      |> BookController.load_from_query
    render(conn, "index.html", books: resources, page_count: number_of_pages, current_page: n, filtered: false)
  end

  def number_of_pages do
    count = 
      Book
      |> Resource.count
      |> Repo.all
      |> List.first
    Float.ceil(count / @entries_per_page)
    |> Kernel.trunc
  end
end