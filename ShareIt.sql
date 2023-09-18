DROP VIEW if exists statistiche_post;

DROP TABLE IF EXISTS Allegato; 
DROP TABLE IF EXISTS Contenuto; 
DROP TABLE IF EXISTS Iscrizione; 
DROP TABLE IF EXISTS RichiestaIscrizione; 
DROP TABLE IF EXISTS Partecipazione; 
DROP TABLE IF EXISTS Inoltro; 
DROP TABLE IF EXISTS Ricezione; 
DROP TABLE IF EXISTS Blocco; 
DROP TABLE IF EXISTS Commento; 
DROP TABLE IF EXISTS Tag; 
DROP TABLE IF EXISTS MiPiace; 
DROP TABLE IF EXISTS Pagina; 
DROP TABLE IF EXISTS Messaggio; 
DROP TABLE IF EXISTS Gruppo; 
DROP TABLE IF EXISTS ContenutoMultimediale; 
DROP TABLE IF EXISTS Filtro; 
DROP TABLE IF EXISTS Post; 
DROP TABLE IF EXISTS Utente;

DROP DOMAIN IF EXISTS STRINGA;
DROP DOMAIN IF EXISTS TESTO;
DROP DOMAIN IF EXISTS SIGLA;

CREATE DOMAIN STRINGA AS VARCHAR(30);
CREATE DOMAIN TESTO AS VARCHAR(2000);
CREATE DOMAIN SIGLA AS VARCHAR(2);

CREATE TABLE Utente(
	Email STRINGA NOT NULL PRIMARY KEY,
	Nome STRINGA NOT NULL,
	Cognome STRINGA NOT NULL,
	Sesso CHAR(1),
	Eta INT NOT NULL,	
	Password STRINGA NOT NULL,
	Profilo_aziendale BOOL NOT NULL,
	Sigla_stato SIGLA,
	Sigla_citta SIGLA,
	Latitudine FLOAT,
	Longitudine FLOAT,
	CHECK(
	Eta >= 18 and
	Eta < 110 and
	(Sesso ='M' or Sesso = 'F')
	)
);

CREATE TABLE Post (
  	Data_ora TIMESTAMP NOT NULL,
	Uploader STRINGA NOT NULL references Utente(Email)
								ON UPDATE CASCADE
								ON DELETE CASCADE,
	PRIMARY KEY(data_ora, uploader),
	Tipo STRINGA NOT NULL,
	Descrizione TESTO,
	Latitudine FLOAT,
	Longitudine FLOAT,
	Durata INT,
	Sigla_Stato SIGLA,
	Sigla_citta SIGLA,
	CHECK(
		(Tipo = 'Normale' or Tipo = 'Storia') and
		((Tipo = 'Normale' and Durata  IS NULL) or 
		(Tipo = 'Storia' and Durata IS NOT NULL and Descrizione IS NULL))
	)
);

CREATE TABLE Filtro(
	Nome STRINGA NOT NULL PRIMARY KEY,
	Intensita INT NOT NULL,
	Creatore STRINGA references Utente(Email)
						ON UPDATE CASCADE
						ON DELETE CASCADE
);

CREATE TABLE ContenutoMultimediale (
	Id INT NOT NULL PRIMARY KEY,
	Tipo STRINGA NOT NULL,
	Dimensione INT NOT NULL,
	Larghezza INT NOT NULL,
	Altezza INT NOT NULL,
	Audio BOOL,
	Durata INT,
	Filtro STRINGA references Filtro(Nome)
					ON UPDATE CASCADE
					ON DELETE CASCADE,
	CHECK(
		(Tipo = 'Foto' or Tipo = 'Video') and
		((Tipo = 'Foto' and Audio  IS NULL and Durata IS NULL) or 
		(Tipo = 'Video' and Audio IS NOT NULL and Durata IS NOT NULL))
	)
);

CREATE TABLE Gruppo (
	Nome STRINGA NOT NULL,
	Admin STRINGA NOT NULL references Utente(Email)
								ON UPDATE CASCADE
								ON DELETE CASCADE,
	Immagine INT references ContenutoMultimediale(id)
							ON UPDATE CASCADE
							ON DELETE CASCADE,							
	PRIMARY KEY(Nome,Admin)
);

CREATE TABLE Messaggio (
	Data_ora TIMESTAMP NOT NULL,
	Mittente STRINGA NOT NULL references Utente(Email)
								ON UPDATE CASCADE 
								ON DELETE CASCADE,
	PRIMARY KEY(Data_ora,Mittente),
	Testo TESTO
);

CREATE TABLE Pagina(
	Tipo STRINGA NOT NULL,
	Nome STRINGA NOT NULL,
	Quando TIMESTAMP,
	Privata BOOL,
	Descrizione TESTO,
	Sigla_Stato SIGLA,
	Sigla_citta SIGLA,
	Creatore STRINGA NOT NULL references Utente(Email)
								ON UPDATE CASCADE
								ON DELETE CASCADE,
	Copertina INT references ContenutoMultimediale(Id)
					ON UPDATE CASCADE
					ON DELETE CASCADE,
	PRIMARY KEY(Tipo,Nome),
	CHECK(
		(Tipo = 'Utente' or Tipo = 'Community' or Tipo = 'Evento') and
		((Tipo = 'Utente' and Privata IS NOT NULL and Sigla_citta IS NULL and Sigla_Stato IS NULL and Quando IS NULL) or
		(Tipo = 'Community' and Privata IS NULL and Sigla_citta  IS NULL and Sigla_Stato IS NULL and Quando IS NULL) or
		(Tipo = 'Evento' and Privata  IS NULL and Sigla_citta IS NOT NULL and Sigla_Stato IS NOT NULL and Quando IS NOT NULL))
	)
);

CREATE TABLE MiPiace(
	Utente STRINGA NOT NULL references Utente(Email)
							ON UPDATE CASCADE
							ON DELETE CASCADE,
	Data_ora_post TIMESTAMP NOT NULL,
	Uploader_post STRINGA NOT NULL,
	PRIMARY KEY(Utente,Data_ora_post,Uploader_post),
	FOREIGN KEY(Data_ora_post, Uploader_post) references Post(Data_ora, Uploader)
									ON UPDATE CASCADE
									ON DELETE CASCADE
);

CREATE TABLE Tag(
	Utente STRINGA NOT NULL,
	Data_ora_post TIMESTAMP NOT NULL,
	Uploader_post STRINGA NOT NULL,
	Utente_taggato STRINGA NOT NULL,
	PRIMARY KEY(Utente,Data_ora_post,Uploader_post,Utente_taggato),
	FOREIGN KEY(Utente) references Utente(Email)
						ON UPDATE CASCADE
					    ON DELETE CASCADE,
	FOREIGN KEY(Utente_taggato) references Utente(Email)
						ON UPDATE CASCADE
					    ON DELETE CASCADE,
	FOREIGN KEY(Data_ora_post,Uploader_post) references Post(Data_ora,Uploader)
										ON UPDATE CASCADE
										ON DELETE CASCADE							
);

CREATE TABLE Commento(
	Utente STRINGA NOT NULL references Utente(Email)
							ON UPDATE CASCADE
							ON DELETE CASCADE,
	Data_ora_post TIMESTAMP NOT NULL,
	Uploader_post STRINGA NOT NULL,
	Testo TESTO NOT NULL,
	PRIMARY KEY(Utente, Data_ora_post, Uploader_post),
	FOREIGN KEY(Data_ora_post, Uploader_post) references Post(Data_ora, Uploader)
												ON UPDATE CASCADE
												ON DELETE CASCADE
);

CREATE TABLE Blocco(
	Utente STRINGA NOT NULL,
	Utente_bloccato STRINGA NOT NULL,
	PRIMARY KEY(Utente, Utente_bloccato),
	FOREIGN KEY(Utente) references Utente(Email)
						ON UPDATE CASCADE
					    ON DELETE CASCADE,
	FOREIGN KEY(Utente_bloccato) references Utente(Email)
						ON UPDATE CASCADE
					    ON DELETE CASCADE,
	CHECK(
		Utente != Utente_bloccato
	)
);

CREATE TABLE Ricezione(
	Data_ora_messaggio TIMESTAMP NOT NULL,
	Mittente STRINGA NOT NULL,
	Destinatario STRINGA NOT NULL references Utente(Email)
									ON UPDATE CASCADE
									ON DELETE CASCADE,
	PRIMARY KEY(Data_ora_messaggio, Mittente, Destinatario),
	FOREIGN KEY(Data_ora_messaggio, Mittente) references Messaggio(Data_ora,Mittente)
												ON UPDATE CASCADE
												ON DELETE CASCADE
);

CREATE TABLE Inoltro(
	Data_ora_messaggio TIMESTAMP NOT NULL,
	Mittente STRINGA NOT NULL,
	Nome_gruppo STRINGA NOT NULL,
	Admin_Gruppo STRINGA NOT NULL,
	PRIMARY KEY(Data_ora_messaggio, Mittente, Nome_gruppo, Admin_Gruppo),
	FOREIGN KEY(Data_ora_messaggio, Mittente) references Messaggio(Data_ora,Mittente)
												ON UPDATE CASCADE
												ON DELETE CASCADE,
	FOREIGN KEY(Nome_gruppo, Admin_Gruppo) references Gruppo(Nome, Admin)	
										ON UPDATE CASCADE
										ON DELETE CASCADE									
);

CREATE TABLE Partecipazione(
	Utente STRINGA NOT NULL references Utente(Email)
									ON UPDATE CASCADE
									ON DELETE CASCADE,
	Nome_gruppo STRINGA NOT NULL,
	Admin_gruppo STRINGA NOT NULL,
	PRIMARY KEY(Utente,Nome_gruppo, Admin_gruppo),
	FOREIGN KEY(Nome_gruppo, Admin_Gruppo) references Gruppo(Nome, Admin)	
										ON UPDATE CASCADE
										ON DELETE CASCADE		
);

CREATE TABLE RichiestaIscrizione(
	Utente STRINGA NOT NULL references Utente(Email)
									ON UPDATE CASCADE
									ON DELETE CASCADE,
	Nome_pagina STRINGA NOT NULL,
	Tipo_pagina STRINGA NOT NULL,
	PRIMARY KEY(Utente, Nome_pagina, Tipo_pagina),
	FOREIGN KEY(Nome_pagina, Tipo_pagina) references Pagina(Nome, Tipo)	
										ON UPDATE CASCADE
										ON DELETE CASCADE,
	CHECK(
		Tipo_pagina = 'Utente'
	)
);

CREATE TABLE Iscrizione(
	Utente STRINGA NOT NULL references Utente(Email)
									ON UPDATE CASCADE
									ON DELETE CASCADE,
	Nome_pagina STRINGA NOT NULL,
	Tipo_pagina STRINGA NOT NULL,
	PRIMARY KEY(Utente, Nome_pagina, Tipo_pagina),
	FOREIGN KEY(Nome_pagina, Tipo_pagina) references Pagina(Nome, Tipo)	
										ON UPDATE CASCADE
										ON DELETE CASCADE
);

CREATE TABLE Contenuto(
	Data_ora_post TIMESTAMP NOT NULL,
	Uploader_post STRINGA NOT NULL,
	Media INT NOT NULL references ContenutoMultimediale(Id)
						ON UPDATE CASCADE
						ON DELETE CASCADE,
	PRIMARY KEY(Data_ora_post, Uploader_post, Media),
	FOREIGN KEY(Data_ora_post, Uploader_post) references Post(Data_ora, Uploader)
												ON UPDATE CASCADE
												ON DELETE CASCADE
);

CREATE TABLE Allegato(
	Data_ora_messaggio TIMESTAMP NOT NULL,
	Mittente_messaggio STRINGA NOT NULL,
	Media INT NOT NULL references ContenutoMultimediale(Id)
						ON UPDATE CASCADE
						ON DELETE CASCADE,
	PRIMARY KEY(Data_ora_messaggio, Mittente_messaggio, Media),	
	FOREIGN KEY(Data_ora_messaggio, Mittente_messaggio) references Messaggio(Data_ora,Mittente)
												ON UPDATE CASCADE
												ON DELETE CASCADE			
);

INSERT INTO Utente (Email, Nome, Cognome, Sesso,Eta, Password, Profilo_Aziendale, Sigla_stato, Sigla_citta, Latitudine, Longitudine  ) values

('gianni07@gmail.com', 'gianni', 'rossi','M',  '25', 'gianni123','false', 'IT', 'PD', '45.407717', '11.873446'),
('ely34@hotmail.it', 'elisa', 'giacometti', 'F', '34', 'ghjok', 'false', 'IT', 'MI', '45.464194', '9.189635'),
('infobreda@gmail.com', 'giacomo', 'breda', 'M', '51', 'pAstiCceria1234','true', 'IT', 'NA', '40.835885', '14.248768'),
('giulialove@gmail.com', 'giulia', 'friso','F', '19',  'ilovegatti123','false', 'IT', 'CT', '37.502361', '15.087372'),
('enri@gmail.com', 'enrico', 'buso', 'M', '18', 'enriketto18',  'false', 'IT', 'VE', '45.437191', '12.33459'),
('metalshop@gmail.com', 'gennaro', 'catanuso', 'M', '42', 'glsonfo', 'true', 'IT', 'BZ', '46.655942', '11.229637'),
('lorenzogiusti@gmail.com', 'lorenzo', 'giusti', 'M', '20', 'lore6789', 'false', 'IT', 'RM', '41.89332', '12.482932'),
('infovintage@gmail.com', 'luisa', 'neri', 'F','30',  'vintageisme2345',  'true', 'IT', 'LU', '44.017764', '10.45443'),
('bravolu@gmail.com', 'luigi', 'bravo', 'M', '18', 'gigi9023',  'false', 'IT', 'VT', '42.493689', '11.945068'),
('elisabetta00@gmail.com', 'elisabetta', 'fini', 'F', '24', 'fidoismydoc',  'false', 'IT', 'SI', '43.167225', '11.467181'),
('france@gmail.com', 'francesco', 'sturzi', 'M', '20', 'lovefootball333',  'false', 'IT', 'LT', '41.459526', '13.012591'),
('claudia1@gmail.com', 'claudia', 'rossi', 'F', '26', 'd0d0d01', 'false', 'IT', 'BA', '41.125784', '16.862029'),
('dreamboutique@icloud.com', 'emma', 'boschi', 'F', '41', 'boutique167', 'true', 'IT', 'CB', '41.717012', '14.826147'),
('mari@gmail.com', 'leonardo', 'mari', 'M', '22', 'lovesailing222', 'false', 'IT', 'GE', '44.40726', '8.933862'),
('rossanavisa@gmail.com', 'rossana', 'visa', 'F', '53', 'cats1234',  'false', 'IT', 'FG', '41.502811', '15.4529'),
('michela24@gmail.com', 'michela', 'friso', 'F', '19', 'mclfrs', 'false', 'IT', 'GO', '45.944128', '13.625229'),
('gian02@gmail.com', 'gianluca', 'espòosito', 'M', '20', 'versace02', 'false', 'IT', 'TP', '38.017432', '12.515992'),
('cubopizza@libero.it', 'Ernesto', 'Ferri', 'M', '50', 'ilovepizza',  'true', 'IT', 'SS', '40.723264', '8.561007'),
('annadestro@gmail.com', 'anna', 'destro', 'F', '20', 'destro0987y63', 'false', 'IT', 'BR', '40.63592', '17.688443'),
('luke@gmail.com', 'luca', 'sordo', 'M', '24', 'ggmddd', 'false', 'IT', 'PI', '43.71594', '10.401862'),
('45ismynumber@gmail.com', 'Federico', 'Artusi', 'M', '34', 'vekko', 'false', 'IT', 'GE', '44.40726', '8.933862'),
('skishop@icloud.com', 'lorenzo', 'arini', 'M', '32', 'shop_ski2022',  'true', 'IT', 'MI', '45.464194', '9.189635'),
('naccaelisa@gmail.com', 'elisa', 'nacca', 'F', '22', 'fofrj0',  'false', 'IT', 'RM', '41.89332', '12.482932');

INSERT INTO Post (Data_ora, Uploader, Tipo, Descrizione, Durata , Latitudine, Longitudine, Sigla_stato, Sigla_citta) values
('2021-12-03 09:23:36', 'giulialove@gmail.com', 'Normale',  'Ecco i nostri prodotti, passate a trovarci', NULL, '45.465454', '9.186516', 'IT', 'MI'),
('2018-02-06 12:56:35', 'claudia1@gmail.com', 'Normale', 'Latte caldo e piumone', NULL, NULL, NULL, NULL, NULL),
('2020-09-23 18:43:09', 'infovintage@gmail.com', 'Normale', 'Sconti del 50% fino al 30/09!', NULL, '44.017764', '10.45443', 'IT', 'LU'),
('2022-07-31 21:09:35', 'gian02@gmail.com', 'Storia', NULL, '30', NULL, NULL, 'IT', 'RO'),
('2022-11-22 22:10:24', 'metalshop@gmail.com', 'Storia',NULL, '23', NULL, NULL, NULL, NULL),
('2018-01-02 15:23:43', 'lorenzogiusti@gmail.com', 'Normale', 'Sono stanco di lavorare!', NULL, NULL, NULL, NULL, NULL),
('2022-08-28 17:47:00', 'bravolu@gmail.com', 'Normale', 'Out of focus', NULL, NULL, NULL, 'IT', 'BS'),
('2022-04-19 01:23:04', 'ely34@hotmail.it', 'Normale', 'La mia palla di pelo', NULL, NULL, NULL, NULL, NULL),
('2022-05-07 23:56:06', 'giulialove@gmail.com', 'Normale', 'Troppo caldo!', NULL, '42.3489203', '13.3979672', 'IT', 'AQ'),
('2020-12-25 14:09:25', 'giulialove@gmail.com', 'Normale', 'Natale in famiglia', NULL, NULL, NULL, NULL, NULL),
('2017-12-23 13:02:39', 'elisabetta00@gmail.com', 'Storia', NULL, '24', NULL, NULL, NULL, NULL),
('2019-09-10 07:11:37', 'mari@gmail.com', 'Storia', NULL, '56', NULL, NULL, NULL, NULL),
('2019-04-16 09:33:44', 'gianni07@gmail.com', 'Normale', NULL, NULL, '38.1112268', '13.3524434', 'IT', 'PA'),
('2020-06-25 20:56:12', 'mari@gmail.com', 'Storia', NULL, '58', NULL, NULL, NULL, NULL),
('2022-06-20 19:35:15', 'rossanavisa@gmail.com', 'Normale', 'Cats are the best', NULL, NULL, NULL, NULL, NULL),
('2022-07-02 05:44:11', 'rossanavisa@gmail.com', 'Normale', 'Oggi non posto perche il gattino non sta bene', NULL, NULL, NULL, NULL, NULL),
('2020-10-12 09:32:00', 'naccaelisa@gmail.com', 'Normale', 'Sempre io', NULL, '41.5028105', '15.4528996', 'IT', 'FG'),
('2019-11-19 15:01:03', 'skishop@icloud.com', 'Normale', 'Questa stagione abbiamo i prodotti HEAD', NULL, NULL, NULL, NULL, NULL),
('2022-06-14 18:04:05', 'france@gmail.com', 'Storia', NULL, '12', NULL, NULL, NULL, NULL);

INSERT INTO Filtro (nome, intensita) values
('sunset', '7'),
('juno', '4'),
('saturator', '9'),
('cold', '4'),
('glitch', '6'),
('new york', '3'),
('moon', '8'),
('starlight', '5'),
('rave', '10'),
('muse', '4');

INSERT INTO ContenutoMultimediale(Id, Tipo, Dimensione, Larghezza, Altezza, Audio, Durata, Filtro) values
('4567', 'Foto', '11', '1000', '500', NULL, NULL, 'sunset'),
('8903', 'Video', '23', '3000', '2500', 'TRUE', '26', 'juno'),
('5693', 'Foto', '5', '1000', '1000', NULL, NULL, NULL),
('5321', 'Foto', '9', '2500', '3000', NULL, NULL, NULL),
('1234', 'Video', '25', '2000', '2000', 'FALSE', '56', 'sunset'),
('1235', 'Video', '19', '4000', '3000', 'TRUE', '32', NULL),
('1238', 'Foto', '6', '3500', '2000', NULL, NULL, 'glitch'),
('1344', 'Foto', '8', '2300', '1200', NULL, NULL, NULL),
('8905', 'Foto', '9', '1200', '1200', NULL, NULL, NULL),
('1200', 'Foto', '10', '4000', '4000', NULL, NULL, 'moon'),
('4590', 'Video', '28', '2300', '1200', 'TRUE', '45', NULL),
('4591', 'Foto', '6', '3000', '3000', NULL, NULL, 'new york'),
('4592', 'Video', '32', '1200', '2500', 'TRUE', '36', NULL),
('4593', 'Foto', '7', '3000', '2500', NULL, NULL, NULL),
('4594', 'Foto', '6', '1000', '1000', NULL, NULL, 'rave'),
('4595', 'Video', '5', '3000', '3000', 'FALSE', '10', NULL),
('4596', 'Foto', '9', '3000', '3000', NULL, NULL, NULL),
('4597', 'Foto', '12', '1200', '1200', NULL, NULL, NULL),
('4598', 'Video', '24', '2500', '2500', 'TRUE', '60', 'cold'),
('4599', 'Foto', '6', '3000', '2500', NULL, NULL, 'cold'),
('4600', 'Foto', '12', '1000', '1000', NULL, NULL, NULL);

INSERT INTO Gruppo(Nome, Admin, Immagine) values
('las chicas', 'claudia1@gmail.com', '4600'),
('i ragazzi', 'mari@gmail.com', '4599'),
('Calcetto', 'gianni07@gmail.com', '4594'),
('UNI', 'giulialove@gmail.com', '4591'),
('Famiglia', 'enri@gmail.com', '1344'),
('Gruppo padel', 'naccaelisa@gmail.com', '8905'),
('Sabato sera', 'lorenzogiusti@gmail.com', '4597'),
('Vacanza 2022', 'france@gmail.com', '5321'),
('Puglia 2022', 'elisabetta00@gmail.com', '1200'),
('Girls', 'elisabetta00@gmail.com', '4594'),
('Vela club', 'michela24@gmail.com', '4598'),
('Segreteria lavoro', 'ely34@hotmail.it', '1238');

INSERT INTO Messaggio(Testo, Data_ora, Mittente) values
('ciao amo come stai?', '2022-01-01 19:00:01', 'bravolu@gmail.com'),
('sto bene grazie, tu come stai tesoro?', '2022-01-01 19:10:01', 'naccaelisa@gmail.com'),
('bene...oggi ti va di uscire?', '2022-01-01 19:12:41', 'bravolu@gmail.com'),
('alle 21 ti passo a prendere', '2022-01-01 19:25:28', 'naccaelisa@gmail.com'),
('scusa mi daresti una mano a risolvere un esercizio?', '2022-06-09 08:00:02', 'elisabetta00@gmail.com'),
('mi dispiace, ora non ho tempo', '2022-01-01 19:00:01', 'luke@gmail.com'),
('secondo te questo vestito mi sta bene?', '2022-08-02 12:10:32', 'annadestro@gmail.com'),
('si sei bellissima', '2022-08-02 13:20:21', 'lorenzogiusti@gmail.com'),
('grazie lorenzo! allora lo metto domani', '2022-08-02 13:35:11', 'annadestro@gmail.com'),
('secondo te invece questa felpa nuova?', '2022-08-02 15:39:01', 'lorenzogiusti@gmail.com'),
('La adoro!!!!! Vado in palestra ora, ciao lore', '2022-08-02 15:50:53', 'annadestro@gmail.com'),
('sono sotto casa tua', '2022-09-12 21:30:25', 'michela24@gmail.com'),
('metto le scarpe e scendo', '2022-09-12 21:31:04', 'ely34@hotmail.it'),
('ciao fra, organizziamo la vacanza?', '2022-06-09 10:34:35', 'mari@gmail.com'),
('hey guarda che casa pazzesca in puglia che ho trovato','2022-06-09 10:52:12','enri@gmail.com'),
('fighissima, io ho visto questa in sardegna','2022-06-09 11:03:42','mari@gmail.com'),
('figa anche questa, chiediamo il parere degli altri e prenotiamo','2022-06-09 10:55:59','enri@gmail.com'),
('tu cosa ne pensi?', '2022-02-16 16:58:23', 'giulialove@gmail.com'),
('non sono molto convinta', '2022-02-01 17:00:09', 'claudia1@gmail.com'),
('grazie dei consigli te ne sono grata', '2022-02-16 17:15:36', 'giulialove@gmail.com'),
('ragazze facciamo qualcosa sabato!!!!', '2022-03-16 19:15:46', 'claudia1@gmail.com'),
('andiamo a fare vela settimana prossima', '2022-06-23 17:15:36', 'michela24@gmail.com'),
('secondo me è bella questa casa', '2022-05-02 17:15:36', 'mari@gmail.com');


INSERT INTO Pagina(Tipo, Nome, Quando, Privata, Descrizione, Sigla_stato, Sigla_citta, Creatore, Copertina) values
('Utente', 'catsinternet', NULL, 'FALSE', 'Per chi come me ama i gatti!', NULL, NULL, 'rossanavisa@gmail.com', NULL),
('Evento', 'pasticceria.breda', '2022-7-31 20:00:00', NULL, 'Pasticceri con amore dal 1960', 'IT', 'MI', 'infobreda@gmail.com', NULL),
('Community', 'I ragazzi della via pal', NULL, NULL, 'No spam solo qualità', NULL, NULL, 'lorenzogiusti@gmail.com', NULL),
('Utente', 'ellys', NULL, 'FALSE', 'ciao amici!', NULL, NULL, 'elisabetta00@gmail.com', '5321'),
('Utente', 'anonimo45', NULL, 'TRUE', NULL, NULL, NULL, '45ismynumber@gmail.com', NULL),
('Utente', 'peppina', NULL, 'FALSE', NULL, NULL, NULL, 'michela24@gmail.com', '4596'),
('Evento', 'Mamacita party', '2022-10-31 21:00:00', NULL, 'Venite a ballare latino con noi! Tegnue Sottomarina +18', 'IT', 'VE', 'annadestro@gmail.com', NULL),
('Community', 'Crypto club', NULL, NULL, 'Per consigli sulle crypto', NULL, NULL, 'mari@gmail.com', '4600'),
('Utente', 'leonardo-mari', NULL, 'FALSE', 'Matto ma felice', NULL, NULL, 'mari@gmail.com', NULL),
('Evento', 'Conferenza ambiente', '2022-01-10 11:00:00', NULL, 'Conferenza informativa con ospiti esperti. Piazza Duomo', 'IT', 'MI', 'enri@gmail.com', NULL),
('Utente', 'skyscraper', NULL, 'TRUE', NULL, NULL, NULL, 'ely34@hotmail.it', NULL),
('Utente', 'elisa', NULL, 'FALSE', NULL, NULL, NULL, 'claudia1@gmail.com', '1200'),
('Evento', 'Spirit', '2022-06-03 22:00:00', NULL, 'Musica techno all Extra Padova, con ospite Jamie Jones! +18', 'IT', 'PD', 'france@gmail.com', '4593');

INSERT INTO MiPiace(Utente, Data_ora_post, Uploader_post) values
('gian02@gmail.com', '2021-12-03 09:23:36', 'giulialove@gmail.com'),
('elisabetta00@gmail.com', '2021-12-03 09:23:36', 'giulialove@gmail.com'),
('enri@gmail.com', '2021-12-03 09:23:36', 'giulialove@gmail.com'),
('michela24@gmail.com', '2021-12-03 09:23:36', 'giulialove@gmail.com'),
('claudia1@gmail.com', '2020-09-23 18:43:09', 'infovintage@gmail.com'),
('ely34@hotmail.it', '2020-09-23 18:43:09', 'infovintage@gmail.com'),
('ely34@hotmail.it', '2018-01-02 15:23:43', 'lorenzogiusti@gmail.com'),
('mari@gmail.com', '2018-01-02 15:23:43', 'lorenzogiusti@gmail.com'),
('naccaelisa@gmail.com', '2018-01-02 15:23:43', 'lorenzogiusti@gmail.com'),
('france@gmail.com', '2018-01-02 15:23:43', 'lorenzogiusti@gmail.com'),
('luke@gmail.com', '2018-01-02 15:23:43', 'lorenzogiusti@gmail.com'),
('annadestro@gmail.com', '2022-08-28 17:47:00', 'bravolu@gmail.com'),
('annadestro@gmail.com', '2019-09-10 07:11:37', 'mari@gmail.com'),
('lorenzogiusti@gmail.com', '2019-09-10 07:11:37', 'mari@gmail.com'),
('luke@gmail.com', '2019-09-10 07:11:37', 'mari@gmail.com'),
('claudia1@gmail.com', '2019-09-10 07:11:37', 'mari@gmail.com'),
('ely34@hotmail.it', '2019-09-10 07:11:37', 'mari@gmail.com'),
('michela24@gmail.com', '2020-10-12 09:32:00', 'naccaelisa@gmail.com'),
('45ismynumber@gmail.com', '2020-10-12 09:32:00', 'naccaelisa@gmail.com'),
('lorenzogiusti@gmail.com', '2020-10-12 09:32:00', 'naccaelisa@gmail.com'),
('gianni07@gmail.com', '2017-12-23 13:02:39', 'elisabetta00@gmail.com'),
('gianni07@gmail.com', '2018-02-06 12:56:35', 'claudia1@gmail.com'),
('elisabetta00@gmail.com', '2018-02-06 12:56:35', 'claudia1@gmail.com'),
('enri@gmail.com', '2018-02-06 12:56:35', 'claudia1@gmail.com'),
('gian02@gmail.com', '2018-02-06 12:56:35', 'claudia1@gmail.com');

INSERT INTO Tag(utente, Data_ora_post, Uploader_post, Utente_taggato) values
('giulialove@gmail.com', '2021-12-03 09:23:36', 'giulialove@gmail.com', 'ely34@hotmail.it'),
('gianni07@gmail.com', '2022-08-28 17:47:00', 'bravolu@gmail.com', 'enri@gmail.com'),
('annadestro@gmail.com', '2017-12-23 13:02:39', 'elisabetta00@gmail.com', 'naccaelisa@gmail.com'),
('mari@gmail.com', '2019-09-10 07:11:37', 'mari@gmail.com', 'lorenzogiusti@gmail.com'),
('france@gmail.com', '2022-06-14 18:04:05', 'france@gmail.com', 'luke@gmail.com'),
('naccaelisa@gmail.com', '2020-10-12 09:32:00', 'naccaelisa@gmail.com', 'ely34@hotmail.it'),
('michela24@gmail.com', '2018-02-06 12:56:35', 'claudia1@gmail.com', 'ely34@hotmail.it'),
('annadestro@gmail.com', '2022-08-28 17:47:00', 'bravolu@gmail.com', 'luke@gmail.com'),
('mari@gmail.com', '2020-06-25 20:56:12', 'mari@gmail.com', 'luke@gmail.com'),
('45ismynumber@gmail.com', '2022-07-02 05:44:11', 'rossanavisa@gmail.com', 'giulialove@gmail.com');

INSERT INTO Commento(Utente, Data_ora_post, Uploader_post, Testo) values
('france@gmail.com', '2022-08-28 17:47:00', 'bravolu@gmail.com', 'Grande fratello!'),
('annadestro@gmail.com', '2017-12-23 13:02:39', 'elisabetta00@gmail.com', 'Che bella foto eli'),
('luke@gmail.com', '2019-09-10 07:11:37', 'mari@gmail.com', 'mari sempre sul pezzo'),
('enri@gmail.com', '2019-09-10 07:11:37', 'mari@gmail.com', 'gran foto'),
('lorenzogiusti@gmail.com', '2019-09-10 07:11:37', 'mari@gmail.com', 'migliore amico'),
('france@gmail.com', '2019-04-16 09:33:44', 'gianni07@gmail.com', 'ciao gianni!!'),
('bravolu@gmail.com', '2019-04-16 09:33:44', 'gianni07@gmail.com', 'ci vediamo presto gianni'),
('elisabetta00@gmail.com', '2022-04-19 01:23:04', 'ely34@hotmail.it', 'tesoro quando facciamo una foto insieme'),
('gian02@gmail.com', '2018-02-06 12:56:35', 'claudia1@gmail.com', 'sei bellissima'),
('cubopizza@libero.it', '2021-12-03 09:23:36', 'giulialove@gmail.com', 'passa a provare la nostra pizza'),
('infovintage@gmail.com', '2022-05-07 23:56:06', 'giulialove@gmail.com', 'passa in negozio, abbiamo il 50 % di sconto su tutto'),
('luke@gmail.com', '2020-06-25 20:56:12', 'mari@gmail.com', 'mi manchi leo'),
('lorenzogiusti@gmail.com', '2020-06-25 20:56:12', 'mari@gmail.com', 'smettila di postare'),
('france@gmail.com', '2020-06-25 20:56:12', 'mari@gmail.com', 'ciao mari');

INSERT INTO Blocco(Utente, Utente_bloccato) values
('michela24@gmail.com', 'rossanavisa@gmail.com'),
('france@gmail.com', '45ismynumber@gmail.com'),
('luke@gmail.com', '45ismynumber@gmail.com'),
('enri@gmail.com', '45ismynumber@gmail.com'),
('infobreda@gmail.com', 'cubopizza@libero.it'),
('naccaelisa@gmail.com', 'lorenzogiusti@gmail.com'),
('enri@gmail.com', 'infovintage@gmail.com'),
('elisabetta00@gmail.com', 'infovintage@gmail.com'),
('michela24@gmail.com', 'gian02@gmail.com'),
('gianni07@gmail.com', 'ely34@hotmail.it');

INSERT INTO Ricezione(Data_ora_messaggio, Mittente, Destinatario) values
('2022-01-01 19:00:01', 'bravolu@gmail.com', 'naccaelisa@gmail.com'),
('2022-01-01 19:10:01', 'naccaelisa@gmail.com', 'bravolu@gmail.com'),
('2022-01-01 19:12:41', 'bravolu@gmail.com', 'naccaelisa@gmail.com'),
('2022-01-01 19:25:28', 'naccaelisa@gmail.com', 'bravolu@gmail.com'),
('2022-06-09 08:00:02', 'elisabetta00@gmail.com', 'luke@gmail.com'),
('2022-01-01 19:00:01', 'luke@gmail.com', 'elisabetta00@gmail.com'),
('2022-08-02 12:10:32', 'annadestro@gmail.com', 'lorenzogiusti@gmail.com'),
('2022-08-02 13:20:21', 'lorenzogiusti@gmail.com', 'annadestro@gmail.com'),
('2022-08-02 13:35:11', 'annadestro@gmail.com', 'lorenzogiusti@gmail.com'),
('2022-08-02 15:39:01', 'lorenzogiusti@gmail.com', 'annadestro@gmail.com'),
('2022-08-02 15:50:53', 'annadestro@gmail.com', 'lorenzogiusti@gmail.com'),
('2022-09-12 21:30:25', 'michela24@gmail.com', 'ely34@hotmail.it'),
('2022-09-12 21:31:04', 'ely34@hotmail.it', 'michela24@gmail.com'),
('2022-06-09 10:34:35', 'mari@gmail.com', 'enri@gmail.com'),
('2022-06-09 10:52:12', 'enri@gmail.com', 'mari@gmail.com'),
('2022-06-09 11:03:42', 'mari@gmail.com', 'enri@gmail.com'),
('2022-06-09 10:55:59', 'enri@gmail.com', 'mari@gmail.com'),
('2022-02-16 16:58:23', 'giulialove@gmail.com', 'claudia1@gmail.com'),
('2022-02-01 17:00:09', 'claudia1@gmail.com', 'giulialove@gmail.com'),
('2022-02-16 17:15:36', 'giulialove@gmail.com', 'claudia1@gmail.com');

INSERT INTO Inoltro(Data_ora_messaggio, Mittente, Nome_gruppo, Admin_gruppo) values
('2022-03-16 19:15:46', 'claudia1@gmail.com', 'las chicas', 'claudia1@gmail.com'),
('2022-06-23 17:15:36', 'michela24@gmail.com', 'Vela club', 'michela24@gmail.com'),
('2022-05-02 17:15:36', 'mari@gmail.com', 'Vacanza 2022', 'france@gmail.com');

INSERT INTO Partecipazione(Utente, Nome_gruppo, Admin_gruppo) values
('mari@gmail.com', 'Vacanza 2022', 'france@gmail.com'),
('lorenzogiusti@gmail.com', 'Vacanza 2022', 'france@gmail.com'),
('enri@gmail.com', 'Vacanza 2022', 'france@gmail.com'),
('elisabetta00@gmail.com', 'Vacanza 2022', 'france@gmail.com'),
('luke@gmail.com', 'Vacanza 2022', 'france@gmail.com'),
('france@gmail.com', 'Vacanza 2022', 'france@gmail.com'),
('ely34@hotmail.it', 'las chicas', 'claudia1@gmail.com'),
('giulialove@gmail.com', 'las chicas', 'claudia1@gmail.com'),
('annadestro@gmail.com', 'las chicas', 'claudia1@gmail.com'),
('naccaelisa@gmail.com', 'las chicas', 'claudia1@gmail.com'),
('claudia1@gmail.com', 'las chicas', 'claudia1@gmail.com'),
('gian02@gmail.com', 'Calcetto', 'gianni07@gmail.com'),
('mari@gmail.com', 'Calcetto', 'gianni07@gmail.com'),
('luke@gmail.com', 'Calcetto', 'gianni07@gmail.com'),
('france@gmail.com', 'Calcetto', 'gianni07@gmail.com'),
('gianni07@gmail.com', 'Calcetto', 'gianni07@gmail.com'),
('claudia1@gmail.com', 'Vela club', 'michela24@gmail.com'),
('gian02@gmail.com', 'Vela club', 'michela24@gmail.com'),
('naccaelisa@gmail.com', 'Vela club', 'michela24@gmail.com'),
('ely34@hotmail.it', 'Vela club', 'michela24@gmail.com'),
('michela24@gmail.com', 'Vela club', 'michela24@gmail.com');

INSERT INTO RichiestaIscrizione(Utente, Nome_pagina, Tipo_pagina) values
('gianni07@gmail.com', 'anonimo45', 'Utente'),
('michela24@gmail.com', 'skyscraper', 'Utente'),
('claudia1@gmail.com', 'skyscraper', 'Utente'),
('ely34@hotmail.it', 'skyscraper', 'Utente'),
('annadestro@gmail.com', 'skyscraper', 'Utente'),
('mari@gmail.com', 'anonimo45', 'Utente'),
('france@gmail.com', 'anonimo45', 'Utente');

INSERT INTO Iscrizione(Utente, Tipo_pagina, Nome_pagina) values
('giulialove@gmail.com','Utente', 'catsinternet'),
('dreamboutique@icloud.com','Evento', 'Conferenza ambiente'),
('dreamboutique@icloud.com','Utente', 'skyscraper'),
('dreamboutique@icloud.com','Utente', 'elisa'),
('dreamboutique@icloud.com','Community', 'Crypto club'),
('gian02@gmail.com','Community', 'Crypto club'),
('45ismynumber@gmail.com','Utente', 'skyscraper'),
('45ismynumber@gmail.com','Community', 'Crypto club'),
('ely34@hotmail.it','Utente', 'elisa'),
('lorenzogiusti@gmail.com','Utente', 'skyscraper');

INSERT INTO Contenuto(Data_ora_post,Uploader_post,Media) values
('2021-12-03 09:23:36', 'giulialove@gmail.com','5693'),
('2021-12-03 09:23:36', 'giulialove@gmail.com','1235'),
('2022-04-19 01:23:04', 'ely34@hotmail.it','8903'),
('2022-04-19 01:23:04', 'ely34@hotmail.it','5321'),
('2019-09-10 07:11:37', 'mari@gmail.com','8905');

INSERT INTO Allegato(Data_ora_messaggio,Mittente_messaggio,Media) values
('2022-01-01 19:00:01', 'bravolu@gmail.com','4567'),
('2022-01-01 19:00:01', 'bravolu@gmail.com','4590'),
('2022-08-02 13:35:11', 'annadestro@gmail.com','4595'),
('2022-09-12 21:31:04', 'ely34@hotmail.it','4600'),
('2022-03-16 19:15:46', 'claudia1@gmail.com','1238'),
('2022-03-16 19:15:46', 'claudia1@gmail.com','1344');

-- QUERY 1 --------------------------------------------------------------

DROP VIEW if exists statistiche_post;
CREATE VIEW statistiche_post AS
SELECT tmp1.data_ora, uploader, Commenti, Mi_Piace, COUNT (Tag.*) AS Taggati
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
GROUP BY tmp1.data_ora, uploader, Commenti, Mi_Piace;
SELECT * FROM statistiche_post;

-- QUERY 2 --------------------------------------------------------------

SELECT Sigle.Sigla AS Sigla_citta, coalesce(mf.Numero_utenti_maschio,0) as Numero_utenti_maschio , coalesce(mf.Numero_utenti_femmina,0) as Numero_utenti_femmina from(
	Select * from (
		select Sigla_citta as SiglaM, count(*) AS Numero_utenti_maschio 
		from Utente
		Where Sesso = 'M' AND email in (SELECT uploader FROM Post)
		group by Sigla_citta) m
	FULL JOIN(
		select Sigla_citta as SiglaF, count(*) AS Numero_utenti_femmina
		from utente
		Where Sesso='F' AND email in (SELECT uploader FROM Post)
		group by Sigla_citta) f
		on m.SiglaM = f.SiglaF) mf
INNER JOIN(
	select Sigla_citta as Sigla from Utente 
	) as Sigle
on mf.SiglaM = Sigle.Sigla or mf.SiglaF=Sigle.Sigla;

--QUERY 3----------------------------------------------------------------

SELECT utente, data_ora_post
FROM(
	SELECT utente_bloccato
	FROM Blocco
	GROUP BY utente_bloccato
	HAVING COUNT (*) >= 2
) AS tmp JOIN Commento ON utente_bloccato = utente;


--QUERY 4---------------------------------------------------------------


SELECT email, coalesce(Numero_interazioni, 0) AS Numero_interazioni
FROM(
	SELECT uploader, SUM(mi_piace) + SUM(commenti) + SUM(taggati) AS Numero_interazioni
	FROM statistiche_post
	GROUP BY uploader 
) AS tmp RIGHT JOIN Utente ON tmp.uploader = utente.email
ORDER BY coalesce(Numero_interazioni, 0) DESC;

--QUERY 5---------------------------------------------------------------

select 
	(select count(*) from Utente) as Numero_utenti,
	(select count(*) from Gruppo) as Numero_gruppi,
	(select count(*) from Pagina where Tipo = 'Community') as Numero_pagine_community,
	(select count(*) from Pagina where Tipo = 'Evento') as Numero_pagine_evento,
	(select count(*) from Pagina where Tipo = 'Utente') as Numero_pagine_utente,
	(select count(*) from Post) as Numero_post;


-------------------------------------------------------------------------INDICI:

drop index if exists idx_Utente;
create index idx_Utente on Utente(Email);

drop index if exists idx_Post;
create index idx_Post on Post(Data_ora,Uploader);