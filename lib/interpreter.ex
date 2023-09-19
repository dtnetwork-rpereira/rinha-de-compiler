defmodule Interpreter do
  def eval(expression, scope) do
    kind = expression |> Map.get("kind") |> String.downcase()
    parsed_kind = "do_#{kind}" |> String.to_atom()

    apply(Interpreter, parsed_kind, [expression, scope])
  end

  def do_int(expression, _) do
    expression["value"]
  end

  def do_str(expression, _) do
    expression["value"]
  end

  def do_bool(expression, _) do
    expression["value"]
  end

  def do_tuple(expression, scope) do
    first_value = eval(expression["first"], scope)
    second_value = eval(expression["second"], scope)
    {first_value, second_value}
  end

  def do_if(expression, scope) do
    evaluated_condition = eval(expression["condition"], scope)

    if evaluated_condition do
      eval(expression["then"], scope)
    else
      eval(expression["otherwise"], scope)
    end
  end

  def do_first(expression, scope) do
    eval(expression["value"], scope) |> elem(0)
  end

  def do_second(expression, scope) do
    eval(expression["value"], scope) |> elem(1)
  end

  def do_parameter(expression, _) do
    expression["text"]
  end

  def do_let(expression, scope) do
    variable_name = do_parameter(expression["name"], scope)
    variable_value = eval(expression["value"], scope)

    scope = Map.put(scope, variable_name, variable_value)

    eval(expression["next"], scope)
  end

  def do_var(expression, scope) do
    Map.get(scope, expression["text"])
  end

  def do_func(expression, _) do
    %{
      function: fn modified_scope -> eval(expression, modified_scope) end,
      parameters: expression["parameters"]
    }
  end

  def do_call(expression, scope) do
    function = eval(expression["callee"], scope)

    arguments = expression["arguments"]
    parameters = function["parameters"]

    # TODO
    # if () do
    #   raise "Tá errado aí parcero"
    # end

    IO.puts(arguments)
    IO.puts(parameters)

    modified_scope = scope
    idx = 0

    Enum.each(arguments, fn arg ->
      Map.put(modified_scope, parameters[idx], arg)
    end)

    apply(function, expression["arguments"])
  end

  def do_print(expression, scope) do
    value_to_print = eval(expression["value"], scope)

    if is_tuple(value_to_print) do
      parsed_tuple = Tuple.to_list(value_to_print) |> Enum.join(", ")
      IO.puts("(#{parsed_tuple})")
    else
      IO.puts(value_to_print)
    end

    value_to_print
  end

  def do_binary(expression, scope) do
    lhs = eval(expression["lhs"], scope)
    rhs = eval(expression["rhs"], scope)

    try do
      def_name =
        ("do_" <> expression["op"])
        |> String.downcase()
        |> String.to_atom()

      apply(BinaryOp, def_name, [lhs, rhs])
    rescue
      e ->
        IO.puts(
          "There is an error in #{expression["location"]["start"]}:#{expression["location"]["end"]}"
        )

        e
    end
  end
end
