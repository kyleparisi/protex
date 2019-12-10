defmodule Includes do
  def footer() do
    EEx.eval_file("views/includes/footer.html.eex")
  end
end
