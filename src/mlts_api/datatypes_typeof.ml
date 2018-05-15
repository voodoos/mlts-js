open Datatypes

let make_pi ars ats =
  let make_pis =
    List.map2
      (fun a t -> "pi " ^ a ^ "\\ "
                  ^ "typeof " ^ a
                  ^ " " ^ (lp_typ_of_atypl t))
  in
  LpStrings.to_separated_list
    ~nop:true
    " => "
    (make_pis ars ats)
    
let make_typeof_of_list tname =
  let aux i (ty, a) =
    if a > 0 then
      let args = make_args_from_int ~sym:"x" a in
      let argstyps = get_args_typs (ty, a) in
      let pis = make_pi args argstyps in
      let last = match ty with
        | Bindl(_, _) -> lp_typ_of_atypl (get_last_bind (ty, a))
        | _ -> tname in
      (*(List.fold_left (fun acc l -> acc ^ ";"^ (string_of_atypl l)) "" argstyps)
      ^ *)"(" ^ pis ^ " => typeof (X"
      ^ (string_of_int i)
      ^ " "
      ^ (LpStrings.to_separated_list ~nop:true " " args)
      ^ ") " ^ last ^ ")"
    else "typeof X" ^ (string_of_int i)
         ^ " (" ^ (lp_typ_of_atypl (ty, a)) ^ ")"
  in List.mapi (aux)

let typeof_val arity cname tname args typofs =
  let open LpStrings in
  "\ntypeof (" ^ cname  ^ " "
  ^ (if (arity > 0) then (to_separated_list ~nop:true " " args)
    else LpStrings.to_pr args)
  ^ ") " ^ tname
  ^ (if List.length args > 0 then
       " :- "
       ^ (to_separated_list ", " typofs)
       ^ "."
     else ".")
      
let gen_typeof_preds cname atypl =          
  let rec  aux_val cname (typ, i) =
    let thety, tname, bla = match typ with
      | Arrowl(ty, (Consl(tname), _)) -> ty, tname, base_level_arities ty
      | _ -> (typ, i), lp_typ_of_atypl (typ, i), []
    in
    let arg_list = make_args_from_list bla in
    let right_typeof_list = make_typeof_of_list tname bla in
    (typeof_val i cname tname arg_list right_typeof_list)
  in
  (aux_val cname atypl) ^ "\n"
