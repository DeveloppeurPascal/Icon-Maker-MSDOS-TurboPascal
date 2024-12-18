program Icon_Maker;
{
Auteur: Patrick Pr‚martin.
Date: 10/08/1992. 11/08/1992.
Langage: Turbo Pascal 6.0
But: Cr‚ation des fichiers d'extension .ICN contenant des icones en 16 couleurs.
}

uses
    olf_software,
    crt,
    u_sgf,
    u_mou,
    u_icn,
    u_msg,
    u_pal,
    u_m_util,
    u_m_zone,
    u_int10h,
    u_vga_graph,
    u_code_clavier;

const
     num_ver = '1.0';
     dat_ver = '08/11/1992';
     mou_cross = 1;

type
    p_m_zone2 = ^o_m_zone2;
    o_m_zone2 =
      object (o_m_zone)
        ox, oy : integer;
        procedure idle; virtual;
      end;

var
   zone : p_m_zone2;
   icn : p_icn;
   num_couleur,
   om : byte;
   pal : p_pal;
   nom_fich_pal,
   nom_fich_icn : string;
   typ_curs : boolean;

procedure init_zone;
var
   i : byte;
begin
{ Options du menu. }
  zone^.add_zone ('F2  - '+get_msg (1), red, black, 2, 6, 0, true, touche_F2);
  zone^.add_zone ('F3  - '+get_msg (2), red, black, 2, 7, 0, true, touche_F3);
  zone^.add_zone ('F4  - '+get_msg (3), red, black, 2, 8, 0, true, touche_F4);
  zone^.add_zone ('ESC - '+get_msg (4), red, black, 2, 15, 0, false, touche_escape);
{ Barre de couleurs. }
  for i := 0 to 15 do
    begin
      zone^.add_zone (#219, 16+i, 0, 23+i, 21, 0, true, chr (200+i));
      zone^.add_zone (#219, 16+i, 0, 23+i, 22, 0, true, chr (200+i));
    end;
  {endfor}
{ Zone de clic pour le dessin. }
  zone^.add_zone3 (31, 5, 6, 6, true, #255);
{ Zone correspondant … l'icone. }
  zone^.add_zone3 (34, 16, 2, 2, true, #254);
end; { init_zone }

procedure adapte_palette (pal : p_pal);
begin
  if (pal <> nil)
  then
    set_blk_cna_reg (16, 16, pal^);
  {endif}
end; { adapte_palette }

procedure affiche_icone;
var
   i,
   j : word;
   c : byte;
begin
  icn^.aff_sortie (32*8, 15*8);
  for i := 0 to 7 do
    for j := 0 to 15 do
      begin
        c := (icn^.forme [j] [i] and $f0) shr 4;
        boxf (240+i*6, 32+j*3, 240+i*6+1, 32+j*3+1, c+decal_couleur);
        pset (240+i*6+2, 32+j*3+2, white);
        c := icn^.forme [j] [i] and $f;
        boxf (240+i*6+3, 32+j*3, 240+i*6+4, 32+j*3+1, c+decal_couleur);
        pset (240+i*6+5, 32+j*3+2, white);
      end;
    {endfor}
  {endfor}
end; { affiche_icone }

procedure sauvegarde_icn;
begin
  if confirm (get_msg (7))
  then
    begin
      nom_fich_icn := get_fich_name (nom_fich_icn, 'ICN');
      if (get_nom_fichier2 (nom_fich_icn) <> '')
      then
        icn^.save (nom_fich_icn);
      {endif}
    end;
  {endif}
end; { sauvegarde_icn }

procedure chargement_icn;
begin
  if confirm (get_msg (8))
  then
    begin
      nom_fich_icn := get_fich_name (nom_fich_icn, 'ICN');
      if ((icn <> nil) and (get_nom_fichier2 (nom_fich_icn) <> ''))
      then
        begin
          dispose (icn, done);
          icn := new (p_icn, load (nom_fich_icn, black, darkgray, lightgray));
          affiche_icone;
        end;
      {endif}
    end;
  {endif}
end; { chargement_icn }

procedure chargement_pal;
var
   pal : p_pal;
begin
  if confirm (get_msg (8))
  then
    begin
      nom_fich_pal := get_fich_name (nom_fich_pal, 'PAL');
      if (get_nom_fichier2 (nom_fich_pal) <> '')
      then
        begin
          pal := load_pal (nom_fich_pal);
          if (pal <> nil)
          then
            begin
              adapte_palette (pal);
              dispose (pal);
            end;
          {endif}
        end;
      {endif}
    end;
  {endif}
end; { chargement_pal }

procedure scroll_haut;
var
   i,
   j,
   k : byte;
begin
  for i := 0 to 7 do
    begin
      k := icn^.forme [0] [i];
      for j := 1 to 15 do
        icn^.forme [pred (j)] [i] := icn^.forme [j] [i];
      {endfor}
      icn^.forme [15] [i] := k;
    end;
  {endfor}
  affiche_icone;
end; { scroll_haut }

procedure scroll_bas;
var
   i,
   j,
   k : byte;
begin
  for i := 0 to 7 do
    begin
      k := icn^.forme [15] [i];
      for j := 14 downto 0 do
        icn^.forme [succ (j)] [i] := icn^.forme [j] [i];
      {endfor}
      icn^.forme [0] [i] := k;
    end;
  {endfor}
  affiche_icone;
end; { scroll_bas }

procedure scroll_gauche;
var
   i,
   j,
   k : byte;
begin
  for j := 0 to 15 do
    begin
      k := (icn^.forme [j] [0] and $f0) shr 4;
      for i := 0 to 6 do
        icn^.forme [j] [i] := ((icn^.forme [j] [i] and $0f) shl 4) +
                              ((icn^.forme [j] [i+1] and $f0) shr 4);
      {endfor}
      icn^.forme [j] [7] := ((icn^.forme [j] [7] and $0F) shl 4) + k;
    end;
  {endfor}
  affiche_icone;
end; { scroll_gauche }

procedure scroll_droite;
var
   i,
   j,
   k : byte;
begin
  for j := 0 to 15 do
    begin
      k := (icn^.forme [j] [7] and $f) shl 4;
      for i := 7 downto 1 do
        icn^.forme [j] [i] := ((icn^.forme [j] [i-1] and $0f) shl 4) +
                              ((icn^.forme [j] [i] and $f0) shr 4);
      {endfor}
      icn^.forme [j] [0] := ((icn^.forme [j] [0] and $f0) shr 4) + k;
    end;
  {endfor}
  affiche_icone;
end; { scroll_droite }

procedure change_couleur (new_coul : byte);
begin
  if (new_coul < 16)
  then
    begin
      boxf (176+num_couleur*8, 160, 176+8+num_couleur*8, 175, num_couleur+
                                                              decal_couleur);
      num_couleur := new_coul;
      line (176+num_couleur*8, 160, 176+8+num_couleur*8, 175, black);
      line (176+num_couleur*8, 175, 176+8+num_couleur*8, 160, white);
    end;
  {endif}
end; { change_couleur }

procedure get_coord_xy (var i, j : byte);
var
   mx,
   my : integer;
begin
  mx := ((pos_m_x - 30*8*2) shr 1) div 3;
  my := (pos_m_y - 4*8) div 3;
  if ((mx > -1) and (my > -1) and (mx < 16) and (my < 16))
  then
    begin
      i := mx;
      j := my;
    end
  else
    begin
      i := 16;
      j := 16;
    end;
  {endif}
end; { get_coord_xy }

procedure o_m_zone2.idle;
var
   i,
   j,
   c : byte;
   k,
   l : integer;
begin
  get_coord_xy (i, j);
  if ((i < 16) and (j < 16))
  then
    begin
      if (not typ_curs)
      then
        if (mou_select (mou_cross) <> 0)
        then
          begin
            writeln (get_msg (11));
            halt (1);
          end
        else
          begin
            typ_curs := true;
            ox := 16;
            oy := 16;
          end;
        {endif}
      {endif}
      if ((ox <> i) or (oy <> j) or (pos_m_k > 0))
      then
        begin
          for k := i-2 to i+2 do
            for l := j-2 to j+2 do
              begin
                if ((k < 0) or (l < 0) or (k > 15) or (l > 15))
                then
                  c := black
                else
                  if (k mod 2 = 0)
                  then
                    c := (icn^.forme [l] [k div 2] and $f0) shr 4
                  else
                    c := (icn^.forme [l] [k div 2] and $f);
                  {endif}
                {endif}
                boxf (32+(k+2-i)*8, 136+(l+2-j)*8,
                      32+(k+2-i)*8+6, 136+(l+2-j)*8+6,c+decal_couleur);
              end;
            {endfor}
          {endfor}
          line (48, 152, 55, 159, lightgray);
          line (48, 159, 55, 152, darkgray);
          ox := i;
          oy := j;
        end;
      {endif}
    end
  else
    if (typ_curs)
    then
      begin
        if (mou_select (0) <> 0)
        then
          begin
            writeln (get_msg (11));
            halt (1);
          end
        else
          typ_curs := false;
        {endif}
        boxf (32, 136, 71, 175, black);
      end;
    {endif}
  {endif}
end; { o_m_zone2.idle }

function get_couleur (i, j : byte) : byte;
var
   c : byte;
begin
  if (i mod 2 = 0)
  then
    c := (icn^.forme [j] [i div 2] and $f0) shr 4
  else
    c := icn^.forme [j] [i div 2] and $f;
  {endif}
  get_couleur := c;
end; { get_couleur }

procedure set_couleur (i, j, c : byte);
begin
  if (i mod 2 = 0)
  then
    icn^.forme [j] [i shr 1] := ((icn^.forme [j] [i shr 1] and $f) + c*16)
  else
    icn^.forme [j] [i shr 1] := ((icn^.forme [j] [i shr 1] and $f0) + c);
  {endif}
  boxf (240+i*3, 32+j*3, 240+i*3+1, 32+j*3+1, c+decal_couleur);
end; { set_couleur }

procedure met_point;
var
   i,
   j,
   c : byte;
begin
  get_coord_xy (i, j);
  if ((i < 16) and (j < 16))
  then
    begin
      set_couleur (i, j, num_couleur);
      icn^.aff_sortie (32*8, 15*8);
    end;
  {endif}
end; { met_point }

procedure rempli_zone;
var
   i, j, c : byte;

  procedure rempli (i, j : byte);
  begin
    set_couleur (i, j, num_couleur);
    if ((i > 0) and (get_couleur (i-1, j) = c))
    then
      rempli (i-1, j);
    {endif}
    if ((j > 0) and (get_couleur (i, j-1) = c))
    then
      rempli (i, j-1);
    {endif}
    if ((i < 15) and (get_couleur (i+1, j) = c))
    then
      rempli (i+1, j);
    {endif}
    if ((j < 15) and (get_couleur (i, j+1) = c))
    then
      rempli (i, j+1);
    {endif}
  end; { rempli }

begin
  get_coord_xy (i, j);
  if ((i < 16) and (j < 16))
  then
    begin
      c := get_couleur (i, j);
      if (num_couleur <> c)
      then
        begin
          while ((i > 0) and (get_couleur (i-1, j) = c)) do
            dec (i);
          {endwhile}
          while ((j > 0) and (get_couleur (i, j-1) = c)) do
            dec (j);
          {endwhile}
          rempli (i, j);
          affiche_icone;
        end;
      {endif}
    end;
  {endif}
end; { rempli_zone }

procedure affiche_ecran;
begin
  init_zone;
  adapte_palette (pal);
  gotoxy (3, 1);
  textattr := lightblue;
  write ('Icon Maker '+num_ver);
  gotoxy (2, 2);
  textattr := blue;
  write ('(c) Olf Software');
  dessin_cadre (1, 1, 17, 3, darkgray, lightgray, black, white);
  dessin_fleche_zone (22, 21, 1, 2, darkgray, lightgray, gauche, zone, true, #199);
  dessin_fleche_zone (39, 21, 1, 2, darkgray, lightgray, droite, zone, true, #216);
  dessin_fleche_zone (31, 4, 6, 1, darkgray, lightgray, haut, zone, true,
                      touche_haut);
  dessin_fleche_zone (31, 11, 6, 1, darkgray, lightgray, bas, zone, true,
                      touche_bas);
  dessin_fleche_zone (30, 5, 1, 6, darkgray, lightgray, gauche, zone, true,
                      touche_gauche);
  dessin_fleche_zone (37, 5, 1, 6, darkgray, lightgray, droite, zone, true,
                      touche_droite);
  affiche_icone;
  box (31, 135, 72, 176, darkgray);
  box (30, 134, 73, 177, lightgray);
  box (29, 133, 74, 178, white);
  box (28, 132, 75, 179, lightgray);
  box (27, 131, 76, 180, darkgray);
end; { affiche_ecran }

procedure traitement;
var
   fin,
   code_nul : boolean;
   c : char;
begin
  fin := false;
  change_couleur (0);
  repeat
    zone^.test_souris (code_nul, c);
    case code_nul of
      false :
        case c of
          touche_escape : fin := confirm (get_msg (6));
        end;
      true :
        case c of
          touche_f2 : sauvegarde_icn;
          touche_f3 : chargement_icn;
          touche_f4 : chargement_pal;
          touche_haut : scroll_haut;
          touche_bas : scroll_bas;
          touche_gauche : scroll_gauche;
          touche_droite : scroll_droite;
          #200..#215 : change_couleur (ord (c)-200);
          #199 :
            if (num_couleur > 0)
            then
              change_couleur (pred (num_couleur));
            {endif}
          #216 :
            if (num_couleur < 15)
            then
              change_couleur (succ (num_couleur));
            {endif}
          #255 :
            if (pos_m_k = 1)
            then
              met_point
            else
              rempli_zone;
            {endif}
          #254 :
            begin
              icn^.aff_enfonce (32*8, 15*8);
              delay (250);
              icn^.aff_sortie (32*8, 15*8);
            end;
        end;
    end;
  until fin;
end; { traitement }

begin
  typ_curs := false;
  om := get_mode;
  init_licence ('MKICN');
  init_olf_message (mess_shareware);
  init_olf_software ('Icon Maker '+num_ver, '(c) Patrick Premartin '+dat_ver);
  if not (set_mode (19))
  then
    begin
      writeln (get_msg (5));
      halt (1);
    end
  else
    directvideo := false;
  {endif}
  if (mou_register (mou_load (get_file_name ('CROSS.MOU')), mou_cross) <> 0)
  then
    begin
      writeln (get_msg (10));
      halt (1);
    end;
  {endif}
  zone := new (p_m_zone2, init);
  icn := new (p_icn, init (black, darkgray, lightgray));
  decal_couleur := 16;
  new (pal);
  num_couleur := 0;
  nom_fich_pal := '';
  nom_fich_icn := '';
  get_blk_cna_reg (0, 256, pal^);
  affiche_ecran;
  traitement;
  if (zone <> nil)
  then
    dispose (zone, done);
  {endif}
  if (pal <> nil)
  then
    dispose (pal);
  {endif}
  if (icn <> nil)
  then
    dispose (icn, done);
  {endif}
  repeat
  until (set_mode (om) or true);
end.
