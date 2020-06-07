defmodule Bowling do
  defmodule Strike do
    defstruct rolls: []
  end

  defmodule Spare do
    defstruct rolls: []
  end

  defmodule OpenFrame do
    defstruct rolls: []
  end

  defmodule LastFrameStrike do
    defstruct rolls: []
  end

  defmodule LastFrameSpare do
    defstruct rolls: []
  end

  @doc """
  A game is made up of rolls and frames. A frame consists of varying number of rolls depending on
  whether the roll is a strike, a spare or not, and depending on if the roll is in the last frame.
  """
  def start do
    []
  end

  @strike 10
  @frame_count 10
  defguard is_penultimate_frame(game) when length(game) == @frame_count - 1
  defguard is_final_frame(game) when length(game) == @frame_count

  @doc """
  # We are storing the game in reverse. I don't like this because the roll and score functions
  # are different, so a user would have to know that this function returns rolls in reverse chrono
  # order... but it's fine or now.
  """
  def roll(_, roll) when roll > @strike, do: {:error, "Pin count exceeds pins on the lane"}
  def roll(_, roll) when roll < 0, do: {:error, "Negative roll is invalid"}
  def roll([], roll), do: create_new_frame([], roll)

  def roll(game = [latest_frame | _], roll) when is_final_frame(game) do
    if frame_complete?(latest_frame) do
      {:error, "Cannot roll after game is over"}
    else
      play_last_frame(game, roll)
    end
  end

  def roll(game = [latest_frame | _], roll) when is_penultimate_frame(game) do
    if frame_complete?(latest_frame) do
      create_last_frame(game, roll)
    else
      complete_current_frame(game, roll)
    end
  end

  def roll(game = [latest_frame | _], roll) do
    if frame_complete?(latest_frame) do
      create_new_frame(game, roll)
    else
      complete_current_frame(game, roll)
    end
  end

  defp create_last_frame(game, @strike), do: [%LastFrameStrike{rolls: [@strike]} | game]
  defp create_last_frame(game, roll), do: [%OpenFrame{rolls: [roll]} | game]
  defp create_new_frame(game, @strike), do: [%Strike{rolls: [@strike]} | game]
  defp create_new_frame(game, roll), do: [%OpenFrame{rolls: [roll]} | game]

  defp complete_current_frame([latest_frame | rest], current_roll) do
    first_roll = Enum.at(latest_frame.rolls, 0)

    case first_roll + current_roll do
      score when score > @strike -> {:error, "Pin count exceeds pins on the lane"}
      score when score == @strike -> [%Spare{rolls: [first_roll, current_roll]} | rest]
      _ -> [%OpenFrame{rolls: [first_roll, current_roll]} | rest]
    end
  end

  defp frame_complete?(%Strike{}), do: true
  defp frame_complete?(%Spare{}), do: true
  defp frame_complete?(%LastFrameStrike{rolls: rolls}), do: length(rolls) == 3
  defp frame_complete?(%LastFrameSpare{rolls: rolls}), do: length(rolls) == 3
  defp frame_complete?(%{rolls: rolls}), do: length(rolls) == 2

  defp play_last_frame([%LastFrameStrike{rolls: [@strike, second]} | rest], final_roll) do
    if second < @strike && second + final_roll > @strike do
      {:error, "Pin count exceeds pins on the lane"}
    else
      [%LastFrameStrike{rolls: [@strike, second, final_roll]} | rest]
    end
  end

  defp play_last_frame([%LastFrameStrike{rolls: rolls} | rest], current_roll) do
    [%LastFrameStrike{rolls: rolls ++ [current_roll]} | rest]
  end

  defp play_last_frame([%{rolls: [first_roll]} | rest], current_roll) do
    if first_roll + current_roll == @strike do
      [%LastFrameSpare{rolls: [first_roll, current_roll]} | rest]
    else
      [%OpenFrame{rolls: [first_roll, current_roll]} | rest]
    end
  end

  defp play_last_frame([frame = %{rolls: rolls} | rest], current_roll) do
    new_frame = %{frame | rolls: rolls ++ [current_roll]}
    [new_frame | rest]
  end

  @doc """
  Calculating the score requires knowing up to 2 more rolls than the current roll, which can be
  spread up to 2 frames after the current roll.
  """
  def score(frames) when length(frames) < @frame_count do
    {:error, "Score cannot be taken until the end of the game"}
  end

  def score(frames) do
    if Enum.all?(frames, &frame_complete?/1) do
      do_score(Enum.reverse(frames), 0)
    else
      {:error, "Score cannot be taken until the end of the game"}
    end
  end

  def do_score([%Strike{}, %LastFrameStrike{rolls: rolls}], total_score) do
    final_frame_score = Enum.sum(rolls)
    next_two_rolls = rolls |> Enum.take(2) |> Enum.sum()
    total_score + @strike + next_two_rolls + final_frame_score
  end

  def do_score([%Strike{} | rest = [%Strike{}, third | _]], total_score) do
    third_frame_roll = third.rolls |> Enum.at(0)
    do_score(rest, total_score + @strike * 2 + third_frame_roll)
  end

  def do_score([%Strike{} | rest = [next_frame | _]], total_score) do
    do_score(rest, total_score + @strike + Enum.sum(next_frame.rolls))
  end

  def do_score([%Spare{} | rest = [next_frame | _]], total_score) do
    do_score(rest, total_score + @strike + Enum.at(next_frame.rolls, 0))
  end

  def do_score([%{rolls: rolls} | rest], total_score) do
    do_score(rest, total_score + Enum.sum(rolls))
  end

  def do_score([], total_score), do: total_score
end
