defmodule Bookish.CheckOut do
  use Bookish.Web, :model
  import Ecto.Query
  alias Bookish.Circulation

  schema "check_outs" do
    field :checked_out_to, :string
    field :return_date, Ecto.Date
    timestamps()

    belongs_to :book, Bookish.Book
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:book_id, :checked_out_to])
    |> validate_required([:book_id, :checked_out_to])
    |> validate_not_checked_out
  end

  defp validate_not_checked_out(changeset) do
    id = get_field(changeset, :book_id)
    validate_not_checked_out(changeset, id)
  end

  defp validate_not_checked_out(changeset, id) when id == nil do
    changeset
  end

  defp validate_not_checked_out(changeset, id) do
    if Circulation.id_checked_out?(id) do
      changeset
      |> add_error(:checked_out, "Book is already checked out!")
    else
      changeset
    end
  end

  def current(query) do
    from c in query,
    where: is_nil(c.return_date),
    select: c
  end

  def current(query, book_id) do
    from c in query,
    where: is_nil(c.return_date),
    where: c.book_id == ^book_id,
    select: c
  end
end