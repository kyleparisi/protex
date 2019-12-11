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
