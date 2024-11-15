package DbConnect;

use strict;
use warnings;
use DBI;
use Obstacle;

# Constructeur de la classe dbConnect
sub new {
    my ($class, %args) = @_;
    my $self = {
        db_name   => $args{db_name}   || 'helico_br',
        db_user   => $args{db_user}   || 'postgres',
        db_pass   => $args{db_pass}   || 'postgres',
        db_host   => $args{db_host}   || 'localhost',
        # db_port   => $args{db_port}   || 3306,
        # db_driver => $args{db_driver} || 'mysql',
        dbh       => undef,
    };
    bless $self, $class;
    $self->connect_db;
    return $self;
}

# Méthode pour établir la connexion à la base de données
sub connect_db {
    my ($self) = @_;
    my $dsn = "DBI:Pg:dbname=$self->{db_name};host=$self->{db_host};";
    # my $dsn = "DBI:$self->{db_driver}:database=$self->{db_name};host=$self->{db_host};port=$self->{db_port}";
    $self->{dbh} = DBI->connect($dsn, $self->{db_user}, $self->{db_pass}, { RaiseError => 1, PrintError => 0 });
    return $self->{dbh};
}

sub insert_obstacle {
    my ($self, $x1, $y1, $x2, $y2) = @_;
    my $query = "INSERT INTO obstacles (x1, y1, x2, y2) VALUES (?, ?, ?, ?)";
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute($x1, $y1, $x2, $y2);
    $sth->finish;
}

sub get_obstacles {
    my ($self) = @_;
    my $query = "SELECT * FROM obstacles";
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute;
    my @obstacles;
    while (my $row = $sth->fetchrow_hashref) {
        my $obstacle = Obstacle->new(
            x1 => $row->{x1},
            y1 => $row->{y1},
            x2 => $row->{x2},
            y2 => $row->{y2},
        );
        push @obstacles, $obstacle;
    }
    $sth->finish;
    return @obstacles;
}

sub get_tanks {
    my ($self) = @_;
    my $query = "SELECT * FROM tanks";
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute;
    my @tank_data;
    while (my $row = $sth->fetchrow_hashref) {
        push @tank_data, {
            x      => $row->{x1},
            dx     => $row->{dx},
            points => $row->{points},
        };
    }
    $sth->finish;

    return @tank_data;
}

sub init_terrain {
    my ($self, $longueur, $largeur) = @_;

    my $query_select = "SELECT COUNT(*) FROM terrain";
    my $sth_select = $self->{dbh}->prepare($query_select);
    $sth_select->execute;
    my ($count) = $sth_select->fetchrow_array;

    if ($count > 0) {
        # Mettre à jour les dimensions du terrain
        my $query_update = "UPDATE terrain SET longueur = ?, largeur = ?";
        my $sth_update = $self->{dbh}->prepare($query_update);
        $sth_update->execute($longueur, $largeur);
        $sth_update->finish;
    } else {
        # Insérer les dimensions du terrain
        my $query_insert = "INSERT INTO terrain (longueur, largeur) VALUES (?, ?)";
        my $sth_insert = $self->{dbh}->prepare($query_insert);
        $sth_insert->execute($longueur, $largeur);
        $sth_insert->finish;
    }
}
sub init_points {
    my ($self, $depart, $arrivee) = @_;

    my $query_select = "SELECT COUNT(*) FROM depart";
    my $sth_select = $self->{dbh}->prepare($query_select);
    $sth_select->execute;
    my ($count) = $sth_select->fetchrow_array;

    if ($count > 0) {
        # Mettre à jour les points de départ
        my $query_update = "UPDATE depart SET x1 = ?, y1 = ?, x2 = ?, y2 = ?";
        my $sth_update = $self->{dbh}->prepare($query_update);
        $sth_update->execute($depart->{x1}, $depart->{y1}, $depart->{x2}, $depart->{y2});
        $sth_update->finish;

        # Mettre à jour les points d'arrivée
        $query_update = "UPDATE arrivee SET x1 = ?, y1 = ?, x2 = ?, y2 = ?";
        $sth_update = $self->{dbh}->prepare($query_update);
        $sth_update->execute($arrivee->{x1}, $arrivee->{y1}, $arrivee->{x2}, $arrivee->{y2});
        $sth_update->finish;
    } else {
        # Insérer les points de départ
        my $query_insert = "INSERT INTO depart (x1, y1, x2, y2) VALUES (?, ?, ?, ?)";
        my $sth_insert = $self->{dbh}->prepare($query_insert);
        $sth_insert->execute($depart->{x1}, $depart->{y1}, $depart->{x2}, $depart->{y2});
        $sth_insert->finish;

        # Insérer les points d'arrivée
        $query_insert = "INSERT INTO arrivee (x1, y1, x2, y2) VALUES (?, ?, ?, ?)";
        $sth_insert = $self->{dbh}->prepare($query_insert);
        $sth_insert->execute($arrivee->{x1}, $arrivee->{y1}, $arrivee->{x2}, $arrivee->{y2});
        $sth_insert->finish;
    }
}

sub get_terrain {
    my ($self) = @_;
    my $query = "SELECT longueur, largeur FROM terrain";
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute;
    my ($longueur, $largeur) = $sth->fetchrow_array;
    $sth->finish;
    return ($longueur, $largeur);
}
sub get_depart {
    my ($self) = @_;

    my $query = "SELECT x1, y1, x2, y2 FROM depart";
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute;

    my ($x1, $y1, $x2, $y2) = $sth->fetchrow_array;
    $sth->finish;

    # Créer un objet Obstacle avec les coordonnées récupérées
    my $depart = Obstacle->new(x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2);
    return $depart;
}

sub get_arrivee {
    my ($self) = @_;

    my $query = "SELECT x1, y1, x2, y2 FROM arrivee";
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute;

    my ($x1, $y1, $x2, $y2) = $sth->fetchrow_array;
    $sth->finish;

    # Créer un objet Obstacle avec les coordonnées récupérées
    my $arrivee = Obstacle->new(x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2);
    return $arrivee;
}




1;
