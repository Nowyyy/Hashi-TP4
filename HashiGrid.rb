require 'gtk3'
load "Sauvegarde.rb"
load "MainMenu.rb"
load "UndoRedo.rb"

##
# Cette classe représente la grille
# contenant les boutons ( autrement dit les noeuds , et les
#  ponts d'un point de vue graphique )
# Il y  à peu de méthode encore mais ça arrive
class HashiGrid < Gtk::Grid 

    # @diff        -> Attribut correspondant au niveau de difficulté de la grille
    # @nomniv      -> Attribut correspondant au nom du niveau
    # @x           -> Nombre de colonnes 
    # @y           -> Nombre de lignes 
    # @undoRedo    -> Attribut de type UndoRedo 
    # @nb_iles     -> Nombres d'iles contenues dans la grille
    # @sommets     -> Attribut correspondant au nombre de sommets contenus dans la grille
    # @nodeLink    -> Tableau permettant de contenir temporairement les deux cases cliquées
    # @saveManager -> Attribut de type Sauvegarde


    
    # Attribut de type Sauvegarde
    attr_accessor :saveManager

    # Nombre de colonnes 
    attr_accessor :colonnes
    
    # Nombre de lignes
    attr_accessor :lignes

    # Tableau permettant de contenir temporairement les deux cases 
    # cliquées 
    attr_accessor :nodeLink

    # Attribut correspondant au niveau de difficulté de la grille
    attr_reader :diff

     # Attribut correspondant au nombre de sommets contenus dans la grille
    attr_accessor :sommets 

     # Attribut correspondant au nom du niveau
    attr_reader :nomniv

    # Attribut de type UndoRedo 
    attr_reader :undoRedo

    # Constructeur de la grille 
    # * +nomniv+ Nom du niveau
    # * +diff+  Difficulté du niveau
    # * +x+ Nombre de colonnes
    # * +y+ Nombre de lignes 
    def initialize(nomniv,diff, x,y)
        super()
        @diff = diff
        @nomniv=nomniv
        @x=x
        @y=y
        @undoRedo = UndoRedo.new 
        @nb_iles = 0
        @sommets = Array.new()
        @nodeLink = []
        @saveManager = Sauvegarde.new(nomniv, diff)
    end
    
    # Active le retour en arrière
    def undoPrevious 
        if !@undoRedo.undoStack.empty?
          
            n2 = @undoRedo.undoStack.pop()
            n1 = @undoRedo.undoStack.pop()
            
            @undoRedo.redoStack << n2
            @undoRedo.redoStack << n1
            
            supprimePont(n2,n1, true)
        end

        return self
    end

    # Active le retour en avant
    def redoPrevious
        if !@undoRedo.redoStack.empty?
            n2 = @undoRedo.redoStack.pop()
            n1 = @undoRedo.redoStack.pop()

            @undoRedo.undoStack << n2
            @undoRedo.undoStack << n1
            
            
            ajoutPont(n2,n1)
        end

        return self
    end

    # Methode permettant de lancer les traitements lié aux cases
    # - Ajout d'un pont
    # - Suppression d'un pont
    # - Récupération des cases cliquées conservé par le SaveManager
    def handleClick() 
        @nodeLink.first.choixPossible()
        if( @nodeLink.length >= 2 )
            @nodeLink.first.enleverChoixPossible()
            # Si l'utilisateur clique autre part que sur le bouton REDO
            # La pile du REDO est vidé
            if !@undoRedo.redoStack.empty?
                @undoRedo.redoStack.clear()
            end

            p2 = @nodeLink.pop()
            p1 = @nodeLink.pop()
          
            if ajoutValid?(p1,p2) == true
               
                #Important pour les REDOS et Undo de conserver
                # Sauvegarde les case cliqué 
                @undoRedo.undoStack << p1 
                @undoRedo.undoStack << p2
                
                ajoutPont(p1,p2)
                saveManager.sauvegarder(self)
                $window.partiFini
            end
        end

        return self
    end

    #  Vérifie si la grille est fini 
    #  autrement dit que tous les noeuds ont correment été remplis
    def grilleFini? 
        for x in 0..(self.lignes-1)
            for y in 0..(self.colonnes-1)
                ile = self.get_child_at(x,y)
                if (ile.status == 'i')
                    if !ile.estComplet
                        return false
                    end
                end
            end
        end
        return true
    end

    # Méthode permettant de notifier la grille qu'une case à été cliquée
    def notify(_case)
        @nodeLink << _case
        handleClick()
    end

    # Ajoute un pont entre deux iles
    def ajoutPont(n1,n2)

        # incrémente le nombre de pont sur les iles
        n1.inc()
        n2.inc()

        # Récupère les cases entre les deux iles ( le pont )
        ponts = getPontEntre(n1,n2)

        # Ile Nord
        if n1.northNode == n2 
			n1.northEdge = n1.northEdge + 1
			n2.southEdge = n2.southEdge + 1 
            n1.update
            n2.update

        elsif n1.eastNode == n2  #Ile droit
            n1.eastEdge = n1.eastEdge + 1
			n2.westEdge = n2.westEdge + 1
            n1.update
            n2.update

        elsif n1.westNode == n2 # Ile gauche

            n1.westEdge = n1.westEdge + 1 
			n2.eastEdge = n2.eastEdge + 1
            n1.update
            n2.update

        elsif n1.southNode == n2 # Ile bas

            n1.southEdge = n1.southEdge + 1
			n2.northEdge = n2.northEdge + 1
            n1.update
            n2.update
            
        else 
            p "Erreur: n2 n'est pas un noeud valide pour n1"
		end
        
        n1.pontRestants
        n2.pontRestants

        # Ajoute le pont entre deux iles
        ponts.each do |pont|
            pont.set_typePont( pont.get_typePont() + 1)
            pont.estDouble = true
            pont.update
        end
	   
        return self
    end


    #  Supprime le pont entre deux iles 
    # * +n1+  Premier pont 
    # * +n2+  Deuxieme pont 
    # * +undo+ Attribut par défaut à false permettant permettant d'adapter le traitement de suppression au besoin 
    def supprimePont(n1, n2, undo = false)
       

         # Récupère les cases entre les deux iles ( le pont )
         ponts = getPontEntre(n1,n2)

        # Mis à jour des pont ( tout du moins de leurs edges )
        if n1.northNode == n2 
			n1.northEdge = 0
			n2.southEdge = 0

        elsif n1.eastNode == n2  #Ile droit
            n1.eastEdge = 0
			n2.westEdge = 0

        elsif n1.westNode == n2 # Ile gauche

            n1.westEdge = 0
			n2.eastEdge = 0

        elsif n1.southNode == n2 # Ile bas

            n1.southEdge = 0
			n2.northEdge = 0
            
        else 
            p "Erreur: n2 n'est pas un noeud valide pour n1"
		end

        # Supprime le pont 
        ponts.each do |pont|
            
            if undo 
                pont.set_typePont( pont.get_typePont -  1 )
            else 
                pont.set_typePont( pont.get_typePont -  ( pont.estDouble ? 2 : 1 ) )
            end
            pont.estDouble = false

            if pont.get_typePont == 0
                pont.set_directionPont(0)
            end
            pont.update
        end

        n1.set_degree( n1.pontRestants )
        n2.set_degree ( n2.pontRestants )
        n1.update
        n2.update
	  
        saveManager.sauvegarder(self)
	    $window.partiFini

        return self
    end

    # Charge les voisins accessibles d'une case en HAUT, BAS, GAUCHE, DROITE
    def chargeVoisins
        for x in 0..(self.lignes-1)
            for y in 0..(self.colonnes-1)
                if (self.get_child_at(x,y).status == 'i')

                    # DROITE
                    for x2 in (x+1).upto(self.lignes-1)
                        if (self.get_child_at(x2, y).status == 'i')
                            self.get_child_at(x, y).eastNode = self.get_child_at(x2,y)
                            break
                        end
                    end

                    #BAS
                    for y2 in (y+1).upto(self.colonnes-1)
                        if (self.get_child_at(x,y2).status == 'i')
                            self.get_child_at(x,y).southNode = self.get_child_at(x,y2)
                            break
                        end
                    end
                    
                    #HAUT
                    for y2 in (y-1).downto(0)
                        if (self.get_child_at(x,y2).status == 'i')
                            self.get_child_at(x,y).northNode = self.get_child_at(x,y2)
                            break
                        end
                    end

                    # Gauche
                    for x2 in (x-1).downto(0)
                        if (self.get_child_at(x2,y).status == 'i')
                            self.get_child_at(x,y).westNode = self.get_child_at(x2,y)
                            break
                        end
                    end
                end
            end        
        end

        return self
    end 


    # Vérifie si l'ajout est valide 
    # Autrement dit :
    # - vérifie si les noeuds sont bien voisins sinon renvoi faux
    # - vérifie si il existe un croisement d'arêtes entre les noeuds 
    # * +n1+ Premier pont 
    # * +n2+ Deuxieme pont
    def ajoutValid?(n1,n2)

            if(n1.northNode != n2 && n1.eastNode != n2 && n1.southNode != n2 && n1.westNode != n2)
                return false;
            end
            
            # Voisins NORD
            if(n1.northNode == n2)
                if(n1.northEdge == 2)
                    supprimePont(n1,n2)
                    return false;
                else
                    # renvoie faux s'il existe déjà un croisement d'arêtes entre ces deux nœuds.
                    for y2 in (n1.row-1).downto(0)
                        if(self.get_child_at(n1.column,y2) == n2) 
                            break;
                        else
                            if(self.get_child_at(n1.column,y2).get_directionPont == 1)
                                return false;
                            end
                        end
                    end
                end
            end
        
            # Voisins DROIT
            if(n1.eastNode == n2)
                if(n1.eastEdge == 2)
                    supprimePont(n1,n2)
                    return false;
                else
                    # renvoie faux s'il existe déjà un croisement d'arêtes entre ces deux nœuds.
                    for x2 in (n1.column+1).upto(self.lignes-1)
                        if(self.get_child_at(x2,n1.row) == n2) 
                            break;
                        else
                            if(self.get_child_at(x2,n1.row).get_directionPont == 2)
                                return false;
                            end
                        end
                    end
                end
            end
            
            # Voisins BAS
            if(n1.southNode == n2)
              
                if(n1.southEdge == 2)
                    supprimePont(n1,n2)
                    return false;
                else
                    # renvoie faux s'il existe déjà un croisement d'arêtes entre ces deux nœuds.
                    for y2 in (n1.row+1).upto(self.colonnes-1)
                        if(self.get_child_at(n1.column,y2) == n2)
                            break;
                        else
                            if(self.get_child_at(n1.column,y2).get_directionPont == 1)
                                return false;
                            end
                        end
                    end
                end
               
            end
             # Voisins GAUCHE
             if(n1.westNode == n2)
                if(n1.westEdge == 2)
                    supprimePont(n1,n2)
                    return false;
                else
                    # renvoie faux s'il existe déjà un croisement d'arêtes entre ces deux nœuds.
                    for x2 in (n1.column-1).downto(0)
                        if(self.get_child_at(x2,n1.row) == n2) 
                            break;
                        else
                            if( self.get_child_at(x2,n1.row).get_directionPont == 2)
                                return false;
                            end
                        end
                    end
                end
            end
        return true
    end

    # Retourne un tableau contenant les cases correspondants aux pont entre deux iles 
    # * +n1+ Premier pont 
    # * +n2+ Deuxieme pont
    def getPontEntre(n1, n2)

        # Tableau temporaire visant à contenir l'index des cases formant le pont
        arr = [] 

        # Cas où la case est le voisin du haut
        if n1.northNode == n2 # Ile HAUT

            for y2 in (n1.row-1).downto(0)
                if(self.get_child_at(n1.column,y2) == n2) 
                    break;
				else
                    self.get_child_at(n1.column,y2).set_directionPont(2)
                    arr << self.get_child_at(n1.column,y2)
                end
			end
        # Cas où la case est le voisin de droite
        elsif n1.eastNode == n2  #Ile droit

            for x2 in (n1.column+1).upto(self.lignes-1)
                if(self.get_child_at(x2,n1.row) == n2) 
                    break;
				else
                    self.get_child_at(x2,n1.row).set_directionPont(1)
                    arr << self.get_child_at(x2,n1.row)
                end
			end
        # Cas où la case est le voisin de gauche   
        elsif n1.westNode == n2 # Ile gauche

            for x2 in (n1.column-1).downto(0)
                if(self.get_child_at(x2,n1.row) == n2) 
                    break;
                else
                    self.get_child_at(x2,n1.row).set_directionPont(1)
                    arr << self.get_child_at(x2,n1.row)
                end
            end

        # Cas où la case est le voisin du bas
        elsif n1.southNode == n2   # Ile bas
            for y2 in (n1.row+1).upto(self.colonnes-1)
                if(self.get_child_at(n1.column,y2) == n2) 
                    break;
                else
                    self.get_child_at(n1.column,y2).set_directionPont(2)
                   arr << self.get_child_at(n1.column,y2)
                end
			end
        end 
        return arr
    end

    # Chargement d'une grille depuis un fichier
    def chargeGrille()
        data = []
        File.foreach(@nomniv).with_index do |line, line_no|
            data << line.chomp
        end
        # Slice permet de récupérer la taille de la matrice 
        # tel que 7:7
        num = data.slice!(0)
        self.colonnes = @x
        self.lignes = @y

        # Parcours des données récupérés afin de charger
        # les boutons
        for i in 0..(data.length() - 1) 
            data[i].split(':').each_with_index do | ch, index| 
                # # Création d'une case 
                if ch != '0'
                    btn = Ile.new(self, ch,index,i)
                    @sommets << btn
                else 
                    btn = Pont.new(self, index, i)
                end

                # On attache la référence de la grille
                self.attach(btn, index,i, 1,1)
            end
        end

        return self
    end

end