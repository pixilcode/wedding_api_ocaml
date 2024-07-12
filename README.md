# Wedding API

An API server written in OCaml, built for use with a wedding website.

## Running the server

The server can be run with the following `dune` command:

```bash
dune exec api_server
```

Optionally the following environment variables can be set:

  * `WEDDING_API_DATA_DIR` (default: `'.'`) - the directory where server data
    will be stored; see [Data](#data) for more info

  * `WEDDING_API_PORT` (default: `5599`)

## Endpoints

The server has the following endpoints:

* `<ANY> /api/health` - a health check endpoint, always returns "Healthy!"

* `POST /api/rsvp` - creates an RSVP; expects form fields `name` (`string`) and
  `guest_count` (`int`)

* `POST /api/note` - creates a note; expects form fields `name` (`string`), `note`
  (`string`), and `user_image` (`file`), along with a CSRF tag

* `GET /api/note/form` - gets a note form; includes a CSRF tag for validation

## Data
The server will create the following data in the data directory:

  * `rsvp.csv` - A CSV file containing all of the responses sent by RSVP

  * `rsvp/` - A directory containing an individual text file for each RSVP
    response

  * `notes/` - A directory containing a folder for each note sent; each note
    folder will have a `note.txt` file and an `image.<extension>` file.