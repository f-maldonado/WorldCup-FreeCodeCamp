#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Primera instruccion: truncar las tablas teams y games para arrancar desde cero cada vez que se ejecute este script.
echo $($PSQL "TRUNCATE teams, games")

# Columnas de archivo games.csv: year,round,winner,opponent,winner_goals,opponent_goals
# La siguiente estructura de control busca:
# 1 - insertar los nombres de equipos (paises) ya sea que aparezca en la columna de WINNER u OPPONENT en la tabla teams (24 filas).
# 2 - insertar cada juego en la tabla games con sus respectivos valores (32 filas)

# El script ejecuta el archivo games.csv, separa los valores de la fila cuando encuentra una coma ',', y asigna valores a las varibles YEAR ROUND etc...
cat games.csv | while IFS="," read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  # El primer objetivo: ingresar los nombres de equipo.
  # Columnas de tabla teams: team_id PKEY, name VARCHAR(50) UNIQUE (name)
  
  # La primera linea del archivo corresponde al nombre de la columna: year, winner,opponent etc.
  # Por lo tanto es lo primero que se lee, en base a esto se genera la condicion para la siguiente estructura
  # Si ($WINNER) es distinto al nombre de la columna (winner)
  if [[ $WINNER != winner ]]
  then
    # Se crea una variable (TEAM_ID) que sirve para consultar si un determinado nombre de equipo ya esta en tabla, 
    # es decir que ya tenga asignado un id. Recordar que las restricciones de la columna name de la tabla teams es UNIQUE,
    # esto significa que cada nombre no se puede repetir, por ende solo corresponde un solo id por nombre.
    TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    # Si el nombre del equipo (name=$'WINNER') no esta en la tabla, a TEAM_ID no se le asigna valor.
    
    # Si TEAM_ID no tiene valor, entonces significa que el nombre no se encuentra en la tabla , y se continua por insertarlo.
    if [[ -z $TEAM_ID ]]
    then
      # Se insertar equipo el nombre a la tabla.
      # Recordatorio: en SQL al insertar un valor a una tabla, devuelve la leyenda: 'INSERT 0 1' esto se utiliza como condicion
      # para ejecutar otra instruccion, en este caso imprime en pantalla que ingreso un valor en la tabla.
      INSERT_WINNER_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$WINNER')")
      if [[ $INSERT_WINNER_RESULT == 'INSERT 0 1' ]] 
      then
        echo Se inserto nombre de equipo: $WINNER en la tabla teams.
      fi
    fi
  fi

  # Con la misma idea de la estructura anterior, se busca insertar los nombres de equipo que no esten en la tabla,
  # por ende se compara el valor leido del archivo games.csv en la columna OPPONENTS con los id de la tabla.
  if [[ $OPPONENT != opponent ]]
  then
    TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    if [[ -z $TEAM_ID ]]
    then
       INSERT_OPPONENT_RESULT=$($PSQL "INSERT INTO teams(name) VALUES('$OPPONENT')")
        if [[ $INSERT_OPPONENT_RESULT == 'INSERT 0 1' ]] 
        then
          echo Se inserto nombre de equipo: $OPPONENT en la tabla teams.
        fi
    fi
  fi
 
  # 2 - inserta cada juego a la tabla games.   
  if [[ $YEAR != "year" ]]
  then
    TEAM_ID_WINNER=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    TEAM_ID_OPPONENT=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")

    INSERT_GAMES=$($PSQL "INSERT INTO games(year, round, winner_goals, opponent_goals, winner_id, opponent_id) VALUES($YEAR, '$ROUND', $WINNER_GOALS, $OPPONENT_GOALS, $TEAM_ID_WINNER, $TEAM_ID_OPPONENT)")
    if [[ $INSERT_GAMES == 'INSERT 0 1' ]] 
    then
      echo Se inserto juego en tabla games.
    fi
  fi
	
  
done
