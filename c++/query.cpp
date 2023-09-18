#include <cstdio>
#include <iostream>
#include <fstream>
#include "C:/Program Files/PostgreSQL/14/include/libpq-fe.h"
using namespace std;

#define PG_HOST "127.0.0.1"
#define PG_USER "postgres"
#define PG_DB "shareit"
#define PG_PASS "1234"
#define PG_PORT 5432

void mostra_query()
{
    cout << endl;
    cout << "QUERY 1:" << endl
         << "STATISTICHE DI UN POST: Funzionalita' che mostra le statistiche dei Post, ovvero il numero di like e commenti ricevuti e il numero di persone che sono state taggate (si crea una vista per poter riutilizzare la query in futuro su qualsiasi post)." << endl
         << endl;
    cout << "QUERY 2:" << endl
         << "SONDAGGIO PROVENIENZA: Seleziona il numero di utenti attivi (che hanno postato almeno una volta) provenienti da ogni citta' e li suddivide per sesso." << endl
         << endl;
    cout << "QUERY 3:" << endl
         << "BLOCCATI: Se un utente e' stato bloccato piu' di 2 volte tutti i commenti dell utente bloccato verranno nascosti." << endl
         << endl;
    cout << "QUERY 4:" << endl
         << "INFLUENCER: Fornisce una lista ordinata degli utenti piu' famosi sulla piattaforma (che hanno ricevuto piu' interazioni, ovvero like, tag, commenti e messaggi)." << endl
         << endl;
    cout << "QUERY 5:" << endl
         << "STATISTICHE GLOBALI: Pensata per gli amministratori di ShareIT, visualizza le statistiche globali della piattaforma: il numero di utenti, gruppi, pagine community, pagine evento, pagine  utente, post." << endl << endl << endl;
};

PGresult *Query1(PGconn *conn)
{
    return PQexec(conn, "SELECT tmp1.data_ora, uploader, Commenti, Mi_Piace, COUNT (Tag.*) AS Taggati \
                        FROM ( \
	                        SELECT tmp.data_ora, uploader, Commenti, COUNT (MiPiace.*) AS Mi_Piace \
	                        FROM( \
		                        SELECT Post.data_ora, uploader, COUNT (commento.*) AS Commenti \
		                        FROM Post LEFT JOIN Commento ON Post.data_ora = Commento.data_ora_post AND Post.uploader = Commento.uploader_post \
		                        GROUP BY Post.data_ora, uploader \
	                        ) AS tmp \
	                        LEFT JOIN MiPiace ON MiPiace.data_ora_post = tmp.data_ora AND MiPiace.uploader_post = tmp.uploader \
	                    GROUP BY tmp.data_ora, uploader, Commenti \
                        ) AS tmp1 \
                        LEFT JOIN Tag ON Tag.data_ora_post = tmp1.data_ora AND Tag.uploader_post = tmp1.uploader \
                        GROUP BY tmp1.data_ora, uploader, Commenti, Mi_Piace;");
};

PGresult *Query2(PGconn *conn)
{
    return PQexec(conn, "SELECT Sigle.Sigla AS Sigla_citta, coalesce(mf.Numero_utenti_maschio,0) as Numero_utenti_maschio , coalesce(mf.Numero_utenti_femmina,0) as Numero_utenti_femmina from( \
                            SELECT * \
                            from( \
                                SELECT Sigla_citta as SiglaM, COUNT(*) AS Numero_utenti_maschio \
                                from Utente \
                                WHERE Sesso = 'M' AND email in(SELECT uploader FROM Post) \
                                group by Sigla_citta) m \
                            FULL JOIN( \
                                SELECT Sigla_citta as SiglaF, COUNT(*) AS Numero_utenti_femmina \
                                from utente \
                                WHERE Sesso = 'F' AND email in(SELECT uploader FROM Post) \
                                group by Sigla_citta) f \
                                ON m.SiglaM = f.SiglaF) mf \
                        INNER JOIN( \
                            SELECT Sigla_citta as Sigla from Utente) as Sigle \
                            ON mf.SiglaM = Sigle.Sigla or mf.SiglaF = Sigle.Sigla;");
};

PGresult *Query3(PGconn *conn)
{
    return PQexec(conn, "SELECT utente, data_ora_post \
                        FROM( \
	                        SELECT utente_bloccato \
	                        FROM Blocco \
	                        GROUP BY utente_bloccato \
	                        HAVING COUNT (*) >= 2 \
                        ) AS tmp JOIN Commento ON utente_bloccato = utente");
};

PGresult *Query4(PGconn *conn)
{
    return PQexec(conn, "SELECT email, coalesce(Numero_interazioni, 0) AS numero_interazioni \
                        FROM( \
	                        SELECT uploader, SUM(mi_piace) + SUM(commenti) + SUM(taggati) AS Numero_interazioni \
	                        FROM statistiche_post \
	                        GROUP BY uploader \
                        ) AS tmp RIGHT JOIN Utente ON tmp.uploader = utente.email \
                        ORDER BY coalesce(Numero_interazioni, 0) DESC");
};

PGresult *Query5(PGconn *conn)
{
    return PQexec(conn, "SELECT \
	                    (SELECT COUNT(*) from Utente) AS Numero_utenti, \
	                    (SELECT COUNT(*) from Gruppo) AS Numero_gruppi, \
	                    (SELECT COUNT(*) from Pagina WHERE Tipo = 'Community') AS Numero_pagine_community, \
	                    (SELECT COUNT(*) from Pagina WHERE Tipo = 'Evento') AS Numero_pagine_evento, \
	                    (SELECT COUNT(*) from Pagina WHERE Tipo = 'Utente') AS Numero_pagine_utente, \
	                    (SELECT COUNT(*) from Post) AS Numero_post");
};

void stampaRisultati(PGresult *res)
{
    int tuple = PQntuples(res);
    int campi = PQnfields(res);
    for (int i = 0; i < campi; ++i)
    {
        cout << PQfname(res, i) << "\t\t";
    }
    cout << endl;
    for (int i = 0; i < tuple; ++i)
    {
        for (int j = 0; j < campi; ++j)
        {
            cout << PQgetvalue(res, i, j) << "\t\t";
        }
        cout << endl;
    }
};

int main(int argc, char **argv)
{
    char conninfo[250];
    sprintf(conninfo, " user =%s password =%s dbname =%s hostaddr =%s port =%d", PG_USER, PG_PASS, PG_DB, PG_HOST, PG_PORT);
    PGconn *conn = PQconnectdb(conninfo);
    if (PQstatus(conn) != CONNECTION_OK)
    {
        cout << "Errore di connessione" << PQerrorMessage(conn);
        PQfinish(conn);
        exit(1);
    }
    else
    {
        cout << "Connessione avvenuta correttamente" << endl;
        mostra_query();
        int query = 1;
        while (query != 0)
        {
            cout<< "Scrivere il numero della query da eseguire." << endl << "Scrivere 0 per uscire dal programma" << endl << endl;
            cin >> query;
            PGresult *res;
            switch (query)
            {
            case 1:
                res = Query1(conn);
                break;
            case 2:
                res = Query2(conn);
                break;
            case 3:
                res = Query3(conn);
                break;
            case 4:
                res = Query4(conn);
                break;
            case 5:
                res = Query5(conn);
                break;
            default:
                break;
            }
            if (PQresultStatus(res) != PGRES_TUPLES_OK){
                cout << "Risultati inconsistenti!" << PQerrorMessage(conn) << endl;
            }
            else stampaRisultati(res);
            PQclear(res);
        }
        PQfinish(conn);
        return 0;
    }
}