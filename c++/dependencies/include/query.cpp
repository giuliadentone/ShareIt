#include <cstdio>
#include <iostream>
#include <fstream>
#include "dependencies/include/libpq-fe.h"
using namespace std;

#define PG_HOST "127.0.0.1" 
#define PG_USER "postgres"
#define PG_DB "ShareIt" 
#define PG_PASS "1234" 
#define PG_PORT 5432

void mostra_query(){
    cout << "QUERY 1:" << endl << "STATISTICHE DI UN POST: Funzionalita' che mostra le statistiche dei Post, ovvero il numero di like e commenti ricevuti e il numero di persone che sono state taggate (si crea una vista per poter riutilizzare la query in futuro su qualsiasi post)." << endl << endl;
    cout << "QUERY 2:" << endl << "SONDAGGIO PROVENIENZA: Seleziona il numero di utenti attivi (che hanno postato almeno una volta) provenienti da ogni citta' e li suddivide per sesso." << endl << endl;
    cout << "QUERY 3:" << endl << "BLOCCATI: Se un utente e' stato bloccato piu' di 2 volte tutti i commenti dell utente bloccato verranno nascosti." << endl << endl;
    cout << "QUERY 4:" << endl << "INFLUENCER: Fornisce una lista ordinata degli utenti piu' famosi sulla piattaforma (che hanno ricevuto piu' interazioni, ovvero like, tag, commenti e messaggi)." << endl << endl;
    cout << "QUERY 5:" << endl << "STATISTICHE GLOBALI: Pensata per gli amministratori di ShareIT, visualizza le statistiche globali della piattaforma: il numero di utenti, gruppi, pagine community, pagine evento, pagine  utente, post.";
};

void checkResults(PGresult* res, const PGconn* conn){
    if(PQresultStatus(res) != PGRES_TUPLES_OK){
        cout << "Risultati inconsistenti!" << PQerrorMessage(conn) << endl;
        PQclear(res);
        exit(1);
    }
};

PGresult* Query1(){
    PGresult* res ;
    res = PQexec(conn, "SELECT tmp1.data_ora, uploader, Commenti, Mi_Piace, COUNT (Tag.*) AS Taggati
FROM (
	SELECT tmp.data_ora, uploader, Commenti, COUNT (MiPiace.*) AS Mi_Piace
	FROM(
		SELECT Post.data_ora, uploader, COUNT (commento.*) AS Commenti
		FROM Post LEFT JOIN Commento on Post.data_ora = Commento.data_ora_post AND Post.uploader = Commento.uploader_post
		GROUP BY Post.data_ora, uploader
	) AS tmp 
	LEFT JOIN MiPiace on MiPiace.data_ora_post = tmp.data_ora AND MiPiace.uploader_post = tmp.uploader
	GROUP BY tmp.data_ora, uploader, Commenti
) AS tmp1
LEFT JOIN Tag on Tag.data_ora_post = tmp1.data_ora AND Tag.uploader_post = tmp1.uploader
GROUP BY tmp1.data_ora, uploader, Commenti, Mi_Piace;");
    checkResults (res, conn);
};

PGresult* Query2(){
    PGresult* res ;
    res = PQexec(conn, "SELECT * FROM hubs");
    checkResults (res, conn);
};

PGresult* Query3(){
    PGresult* res ;
    res = PQexec(conn, "SELECT * FROM hubs");
    checkResults (res, conn);
};

PGresult* Query4(){
    PGresult* res ;
    res = PQexec(conn, "SELECT * FROM hubs");
    checkResults (res, conn);
};

PGresult* Query5(){
    PGresult* res ;
    res = PQexec(conn, "SELECT * FROM hubs");
    checkResults (res, conn);
};


void stampaRisultati(){
    int tuple = PQntuples(res);
    int campi = PQnfields (res);
    for(int i = 0; i < campi; ++ i){
        cout << PQfname(res, i) << "\t\t";
    }
    cout << endl ;
    for(int i = 0; i < tuple; ++ i ){
        for(int j = 0; j < campi; ++ j){
            cout << PQgetvalue (res, i, j) << "\t\t";
        }
        cout << endl ;
    }
};

int main (int argc, char ** argv){
    char conninfo [250];
    sprintf(conninfo, " user =%s password =%s dbname =%s hostaddr =%s port =%d", PG_USER , PG_PASS , PG_DB , PG_HOST , PG_PORT);
    PGconn *conn = PQconnectdb(conninfo);
    if(PQstatus(conn) != CONNECTION_OK){
        cout << " Errore di connessione " << PQerrorMessage(conn);
        PQfinish(conn);
        exit(1);
    }
    else { 
        cout << "Connessione avvenuta correttamente";
        mostra_query();
        int query;
        cin >> query;
        while(query != 0){
        PGresult * res;
        switch (query)
        {
            case 1:
                res = Query1();
                break;
            case 2:
                res = Query2();
                break;
            case 3:
                res = Query3();
                break;
            case 4:
                res = Query4();
            case 5:
                res = Query5();
            default:
            break;
    }
    if (PQresultStatus(res) != PGRES_TUPLES_OK){
        cout << " Risultati inconsistenti!" << PQerrorMessage(conn) << endl;
        PQclear(res);
        return;
    }
    stampaRisultati(res);
    cin >> query;
    PQclear ( res );
    PQfinish ( conn );
    }  
}