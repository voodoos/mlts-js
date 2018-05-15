open Datatypes

let arity_type_of_atypl =
  let rec aux c (ty, i) =
    match ty with
    | Consl(_) -> "tm"
    | Bindl(at1, at2)
      -> let r1, r2 = aux c at1, aux c at2 in
         "(" ^ r1 ^ " -> " ^ r2 ^ ")"         
    | Listl(at1)
      -> let r1 = aux c at1 in
         r1
    | Arrowl(at1, at2)
      -> let r1, r2 = aux (c+1) at1, aux (c+1) at2 in
         if c = 0 then
           r1 ^ " -> " ^ r2
         else r1
    | Suml(l) -> if i > 0 then
                   LpStrings.to_separated_list ~nop:true
                     " -> "
                     (List.map (aux c) l)
                 else "tm"
  in
  aux 0
    
let gen_sig cname atypl =
  let aux_val name =
    "\ntype " ^ name ^ " "
    ^ arity_type_of_atypl atypl
    ^ "."
  in
  let tname = match atypl with
    | Arrowl(ty, (Consl(tname), _)), _ -> tname
    | _, _ -> lp_typ_of_atypl atypl
  in
  
  "\ntype " ^ tname ^ " ty."
  ^ (aux_val cname)     
