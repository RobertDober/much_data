defmodule MuchData.Types do
  defmacro __using__(_opts \\ []) do
    quote do
      @type binaries :: [binary()]
      @type maybe_error(t) :: t | no_return()
      @type file_walker_fn() :: (prefixed(), any() -> any())
      @type maybe(t) :: t | nil
      @type prefixed :: {binary(), binaries()}
    end
  end
end
