# Protex

> You Must Construct Additional Pylons!

A naive and simple framework for myself.

## Usage

#### Setup

```bash
mix deps.get
cp .env.default .env
# update .env with your apps details
```

#### Server

```bash
bash local.sh
# open localhost:4000/health
```

#### Testing

Testing requires `docker` and `mysql` clients in your terminal.

```bash
bash test.sh
```

#### Tasks

```bash
bash cli.sh clean_old_sessions
```

## Views

There is special syntax to render views similar to Laravel's blade templates.  Otherwise, [EEx
template](https://hexdocs.pm/eex/EEx.html) syntax should work.

#### Data

Data in templates use the following syntax.

```eex
{{ @name || "" }}
```

#### Include

Include a template in the current template.

```eex
<%= @include.("includes.footer") %>
```

#### Extends

Extend a layout template with the current template.

```eex
<%= @extends.("layouts.marketing") %>
```

#### Yield

Render a named "section".

```eex
<%= @yield.("content") %>
```

#### Section

Section is used to define content of yield statements.

```eex
<%= @section.("content") %>
    <div>Hello world!</div>
<%= @endsection.() %>
```

#### Foreach

```eex
<%= @foreach.("item <- @items") %>
    {{ item["name"] }}
<%= @endforeach.() %>
```
