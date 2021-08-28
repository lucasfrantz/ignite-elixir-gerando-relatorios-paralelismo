defmodule GenReport do
  alias GenReport.Parser

  @names [
    "cleiton",
    "daniele",
    "danilo",
    "diego",
    "giuliano",
    "jakeliny",
    "joseph",
    "mayk",
    "rafael",
    "vinicius"
  ]

  @months [
    "janeiro",
    "fevereiro",
    "março",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro"
  ]
  def build(filenames) when is_list(filenames) do
    filenames
    |> Task.async_stream(&build(&1))
    |> Enum.reduce(report_template(), fn {:ok, result}, report -> sum_reports(report, result) end)
  end

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_template(), fn line, report -> sum_values(line, report) end)
  end

  def build(), do: {:error, "Insira o nome de um arquivo"}

  defp sum_values([name, hours, _day, month, year], %{
         "all_hours" => all_hours,
         "hours_per_month" => hours_per_month,
         "hours_per_year" => hours_per_year
       }) do
    all_hours = Map.put(all_hours, name, all_hours[name] + hours)

    hours_per_month = %{
      hours_per_month
      | name => Map.put(hours_per_month[name], month, hours_per_month[name][month] + hours)
    }

    hours_per_year = %{
      hours_per_year
      | name => Map.put(hours_per_year[name], year, hours_per_year[name][year] + hours)
    }

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp sum_reports(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    all_hours = merge_maps(all_hours1, all_hours2)

    hours_per_month = merge_maps(hours_per_month1, hours_per_month2)

    hours_per_year = merge_maps(hours_per_year1, hours_per_year2)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) when is_map(map1) and is_map(map2) do
    Map.merge(map1, map2, fn
      _key, value1, value2 when is_map(value1) and is_map(value2) -> merge_maps(value1, value2)
      _key, value1, value2 -> value1 + value2
    end)
  end

  # defp merge_maps(map1, map2) do
  #   merge_maps(map1, map2)
  # end

  defp report_template do
    all_hours = Enum.into(@names, %{}, &{&1, 0})
    months = Enum.into(@months, %{}, &{&1, 0})
    years = Enum.into(2016..2020, %{}, &{&1, 0})

    hours_per_month = Enum.into(@names, %{}, fn name -> {name, months} end)

    hours_per_year = Enum.into(@names, %{}, fn name -> {name, years} end)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp build_report(all_hours, hours_per_month, hours_per_year) do
    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end
end
