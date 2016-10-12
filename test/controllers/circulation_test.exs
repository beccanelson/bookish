defmodule Bookish.CirculationTest do
  use Bookish.ConnCase

  alias Bookish.Circulation 
  alias Bookish.Book
  alias Bookish.CheckOut
  alias Bookish.TestHelpers, as: Helpers

  @book_attrs %{author_firstname: "some content", author_lastname: "some content", current_location: "some content", title: "some content", year: 2016}

  test "checked_out? returns false if no check_out record exists for the book" do
    book = Repo.insert! %Book{} 

    refute Circulation.checked_out?(book)
  end
  
  test "checked_out? returns true if a check_out record exists for the book" do
    book = Repo.insert! %Book{}
    check_out = 
      Ecto.build_assoc(book, :check_outs, checked_out_to: "Person")
    Repo.insert!(check_out)

    assert Circulation.checked_out?(book) 
  end

  test "checked_out_to returns the name of the person the book is checked out to" do
    book = Repo.insert! %Book{}
    check_out = 
      Ecto.build_assoc(book, :check_outs, checked_out_to: "Person")
    Repo.insert!(check_out)

    assert Circulation.checked_out_to(book) == "Person"
  end

  test "checked_out_to returns nil if the book is currently available" do
    book = Repo.insert! %Book{}

    assert is_nil(Circulation.checked_out_to(book))
  end

  test "set virtual attributes returns an unchanged collection of books if no books are checked out" do
    book = Repo.insert! %Book{}
    coll = [book]

    assert Circulation.set_virtual_attributes(coll) == coll
  end

  test "check_out updates the current location and returns the changed book", %{conn: conn} do
    book = Repo.insert! %Book{"current_location": "A place"}
    conn = post conn, book_check_out_path(conn, :create, book), check_out: %{"checked_out_to": "Person"} 
    updated_book = Circulation.check_out(conn)

    assert is_nil(updated_book.current_location) 
  end

  test "if a check-out record exists for a book in the collection, it returns an updated collection" do
    book = Repo.insert! %Book{}
    coll = [book]
    check_out = 
      Ecto.build_assoc(book, :check_outs, checked_out_to: "Person")
    Repo.insert!(check_out)
    updated_coll = Circulation.set_virtual_attributes(coll)

    assert List.first(updated_coll).checked_out == true
    assert List.first(updated_coll).checked_out_to == "Person"
  end

  test "checked out books returns an empty list if no books are checked out" do
    Repo.insert! %Book{}
    
    assert Helpers.empty? Circulation.checked_out(Book) |> Repo.all 
  end

  test "checked out books queries books that are checked out" do
    book = Repo.insert! %Book{}
    check_out = 
      Ecto.build_assoc(book, :check_outs, checked_out_to: "Person")
    Repo.insert!(check_out)
    
    assert List.first(Circulation.checked_out(Book) |> Repo.all) == book
  end

  test "checked out returns an empty collection if there are no books to query" do
    assert Helpers.empty? Circulation.checked_out(Book) |> Repo.all
  end
  
  test "updates the current location when returning a book with a valid location", %{conn: conn} do
    book = Repo.insert! %Book{}  
    location = "Chicago"

    check_out = 
      Ecto.build_assoc(book, :check_outs, checked_out_to: "Person")
    Repo.insert!(check_out)

    conn = post conn, circulation_path(conn, :process_return, book), book: %{current_location: location}

    assert redirected_to(conn) == book_path(conn, :index)
    assert Repo.get(Book, book.id).current_location == location 
  end

  test "adds a return date to a check_out record when returning a book", %{conn: conn} do
    book = Repo.insert! %Book{}  
    location = "Chicago"

    check_out = 
      Ecto.build_assoc(book, :check_outs, checked_out_to: "Person")
      |> Repo.insert!

    post conn, circulation_path(conn, :process_return, book), book: %{current_location: location}
    assert Repo.get(CheckOut, check_out.id).return_date
  end

  test "once a book is returned, it is no longer checked out", %{conn: conn} do
    book = Repo.insert! %Book{}
    Ecto.build_assoc(book, :check_outs, checked_out_to: "Person")
    |> Repo.insert!

    assert Circulation.set_attributes(book).checked_out

    post conn, circulation_path(conn, :process_return, book), book: %{current_location: "Chicago"}
    
    refute Circulation.set_attributes(book).checked_out
  end
end

