require 'gtk3'
load 'ClassementMoyen.rb'
load 'ClassementFacile.rb'
load 'ClassementDifficile.rb'

class Classement < Gtk::Window
    def initialize
        super
	set_title "Classement"
	set_resizable(true)


	set_default_size 500, 400

	set_window_position Gtk::WindowPosition::CENTER
	
	texte = "<span font_desc = \"Verdana 20\">Classement :</span>\n"

	boxMenu = Gtk::Table.new(15,3,true)
	
	textTitle = Gtk::Label.new()
	textTitle.set_markup(texte)
	btnFacile = Gtk::Button.new(:label => 'Facile')
	btnFacile.signal_connect('clicked'){
		self.set_sensitive(false)
		classement = ClassementFacile.new
		self.set_sensitive(true)
	}
	btnMoyen = Gtk::Button.new(:label => 'Moyen')
	btnMoyen.signal_connect('clicked'){
		self.set_sensitive(false)
		classement = ClassementMoyen.new
		self.set_sensitive(true)
	}
	btnDifficile = Gtk::Button.new(:label => 'Difficile')
	btnDifficile.signal_connect('clicked'){
		self.set_sensitive(false)
		classement = ClassementDifficile.new
		self.set_sensitive(true)
	}
	btnQuitter = Gtk::Button.new(:label => 'Retour')
	btnQuitter.signal_connect('clicked'){
		self.destroy
		MainMenu.new
	}
	

	boxMenu.attach(textTitle, 0,3,1,4)
	boxMenu.attach(btnFacile, 1,2,4,5)

	boxMenu.attach(btnMoyen, 1,2,6,7)

	boxMenu.attach(btnDifficile, 1,2,8,9)


	boxMenu.attach(btnQuitter, 1,2,12,13)

	add(boxMenu)

	show_all
    end
end
