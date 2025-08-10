defmodule LoadBalancerWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext), your module gains a set of
  macros for internationalization:

      import LoadBalancerWeb.Gettext

      # Simple translation
      gettext("Here is the string to translate")

      # Plural translation
      ngettext("Here is the string to translate", "Here are the strings to translate", 3)

      # Domain-based translation
      dgettext("errors", "Here is the error message to translate")

      # And plural domain-based translation
      dngettext("errors", "Here is the error message to translate", "Here are the error messages to translate", 3)

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :load_balancer
end
