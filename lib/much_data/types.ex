defmodule MuchData.Types do
  defmacro __using__(_opts \\ []) do
    quote do
      @type maybe(t) :: t | nil
    end
  end
end
