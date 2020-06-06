defmodule Bowling do
  @doc """
  Creates a new game of bowling that can be used to store the results of
  the game
  """

  # I feel like the Kata setup pushes you in the wrong direction.
  # It's forcing you to have state when you don't need it, as you get
  # all of the rolls in a list. We could just iterate through that
  # list and calculate the score. But having to validate things like
  # No extra rolls adds to the complexity. Is there a way to build those
  # validations into the state model? MISU soup.

  def start do
    %{rolls: [], frames: []}
  end

  @doc """
  Records the number of pins knocked down on a single roll. Returns `any`
  unless there is something wrong with the given number of pins, in which
  case it returns a helpful message.
  """
  def roll(_, roll) when roll > 10 do
    {:error, "Pin count exceeds pins on the lane"}
  end

  def roll(_, roll) when roll < 0 do
    {:error, "Negative roll is invalid"}
  end

  # Last roll hits different.
  def roll(game = %{frames: frames}, roll) when length(frames) == 10 do
    List.last(frames)
    |> case do
      # This is this messy because we treat the 10th frame as one with extra roles, rather than
      # saying you get extra frames maybe.
      {10} -> update_current_frame(game, roll)
      {10, 10} -> update_current_frame(game, roll)
      {10, 10, _} -> {:error, "Pin count exceeds pins on the lane"}
      {10, second} when second + roll > 10 -> {:error, "Pin count exceeds pins on the lane"}
      {10, _} -> update_current_frame(game, roll)
      {first} when first + roll > 10 -> {:error, "Pin count exceeds pins on the lane"}
      {first, second} when first + second == 10 -> update_current_frame(game, roll)
      {_first_roll} -> update_current_frame(game, roll)
      _ -> {:error, "Cannot roll after game is over"}
    end
  end

  def roll(%{rolls: []}, roll) do
    %{rolls: [roll], frames: [{roll}]}
  end

  def roll(game, roll) do
    List.last(game.frames)
    |> case do
      {10} -> start_new_frame(game, roll)
      {_first, _second} -> start_new_frame(game, roll)
      {first} when first + roll > 10 -> {:error, "Pin count exceeds pins on the lane"}
      {_first} -> update_current_frame(game, roll)
    end
  end

  defp start_new_frame(game, roll) do
    %{game | rolls: game.rolls ++ [roll], frames: game.frames ++ [{roll}]}
  end

  defp update_current_frame(game, roll) do
    %{game | rolls: game.rolls ++ [roll], frames: add_roll_to_current_frame(game.frames, roll)}
  end

  defp add_roll_to_current_frame(frames, roll) do
    frames
    # A hack because we are using a list, but ultimately fine.
    |> Enum.with_index()
    |> Enum.map(fn {frame, index} ->
      # The current frame is always the latest frame.
      if index === length(frames) - 1 do
        Tuple.append(frame, roll)
      else
        frame
      end
    end)
  end

  @doc """
  Returns the score of a given game of bowling if the game is complete.
  If the game isn't complete, it returns a helpful message.
  """
  @spec score(any) :: integer | String.t()

  def score(%{frames: frames}) when length(frames) < 10,
    do: {:error, "Score cannot be taken until the end of the game"}

  def score(%{frames: frames, rolls: rolls}) when length(frames) == 10 do
    case List.last(frames) do
      {10} ->
        {:error, "Score cannot be taken until the end of the game"}

      {10, _} ->
        {:error, "Score cannot be taken until the end of the game"}

      {first, second} when first + second == 10 ->
        {:error, "Score cannot be taken until the end of the game"}

      _ ->
        do_score(rolls, 0)
    end
  end

  def score(%{rolls: rolls}) do
    do_score(rolls, 0)
  end

  def do_score([first, second, third], total_score) when first + second == 10 do
    10 + third + total_score
  end

  # Strike at the end
  def do_score([10, second, third], total_score) do
    do_score([second, third], 10 + total_score)
  end

  # Normal End Game
  def do_score([first, second, third], total_score) do
    first + second + third + total_score
  end

  # Spare anywhere else
  def do_score([first, second | rest = [third | _]], total_score) when first + second == 10 do
    do_score(rest, 10 + third + total_score)
  end

  # Strike anywhere else
  def do_score([10 | rest = [second, third | _]], total_score) do
    do_score(rest, 10 + second + third + total_score)
  end

  # Normal Frame anywhere else
  def do_score([first, second | rest], total_score) do
    do_score(rest, first + second + total_score)
  end

  def do_score([_last], total_score), do: total_score
  def do_score([], total_score), do: total_score
end
