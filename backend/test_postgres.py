import psycopg2

conn = psycopg2.connect(
    dbname="boardroom",
    user="boardroom",
    password="boardroom_password",
    host="localhost",
    port="5432",
)

cur = conn.cursor()
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public';")

for row in cur.fetchall():
    print(row[0])

cur.close()
conn.close()
