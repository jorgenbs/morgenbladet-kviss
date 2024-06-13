// -----------------------------------------
// Takes an article slug as input stores questions and answers from
// the kviss api and inserts them into a sqlite database.
//
// Usage example:
// cargo run -- --slug=kviss-2021-03-26 --init
// -----------------------------------------

use clap::Parser;
use rusqlite::{Connection, Result};
use scraper::{self, Html};
use serde_json::Value;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Name of kviss article slug
    #[arg(short, long)]
    slug: String,

    #[arg(short, long)]
    init: bool,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    let connection = get_db_connection(args.init).await?;

    if check_slug_exists(&connection, &args.slug).await? {
        println!("Slug already exists in db");
        return Ok(());
    }

    // Fetch data from kviss api
    let url = format!(
        "https://kviss-admin-api.morgenbladet.no/api/quiz/slug/{}",
        args.slug
    );
    let response = reqwest::get(&url).await?.text().await?;
    let json: Value = serde_json::from_str(&response)?;

    let question_answer_pairs = json["adjacencyPairs"].as_array().unwrap();

    // Insert question/answer pairs into db
    for entry in question_answer_pairs {
        let question = parse_html_string(entry["question"].as_str().unwrap());
        let answer = parse_html_string(entry["answer"].as_str().unwrap());

        let sql = "INSERT INTO quiz_entry (question, answer, slug) VALUES (?1, ?2, ?3)";

        if connection
            .execute(sql, [&question, &answer, &args.slug])
            .is_err()
        {
            panic!("Failed to insert into db");
        }
    }

    Ok(())
}

fn parse_html_string(str: &str) -> String {
    let question_text = Html::parse_fragment(str)
        .root_element()
        .text()
        .collect::<String>();
    let question_text = question_text.replace("'", "''");
    question_text
}

async fn get_db_connection(recover: bool) -> Result<Connection> {
    let connection = Connection::open("./db.sqlite").unwrap();

    let exists = connection
        .prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='quiz_entry'")?
        .exists(());

    // create table if it doesnt exist
    if exists.unwrap() == false {
        if recover {
            println!("Recovering table");
            let create = "CREATE TABLE quiz_entry (id INTEGER PRIMARY KEY AUTOINCREMENT, question TEXT, answer TEXT, slug TEXT);";
            connection.execute(create, ())?;
        } else {
            panic!("Table does not exist, run with --init flag to create table");
        }
    }

    Ok(connection)
}

async fn check_slug_exists(connection: &Connection, slug: &str) -> Result<bool> {
    let mut statement = connection.prepare("SELECT COUNT(slug) FROM quiz_entry WHERE slug=(?1)")?;
    let person_iter = statement.query_row::<u32, _, _>([&slug], |row| row.get(0))?;

    match person_iter {
        0 => Ok(false),
        _ => Ok(true),
    }
}
