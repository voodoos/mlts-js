
exception Unknown_action

(** This file is the main program running the mlts transpiler. 
  * It compiles to mlts-worker.js which is run as
  * a web worker *)

  
(* Callback handling is a bit tricky : messages cannot
 * carry functions so we use unique ids *)
let sendCallbackOrder ?b:(b=true) (payload: 'a Js.t) uuid  =
  let open Js in
  let message = object%js (self) (* Equivalent of this *)
    val type_ = string (if b then "resolve" else "reject")
    val uuid = string uuid
    val value = payload
  end in
  Worker.post_message(message)

let resolve uuid value  = sendCallbackOrder value uuid
let reject uuid err  = sendCallbackOrder ~b:false err uuid


(* The onmessage function is critical for a web worker *)
let onMessage e = 
  let action = Js.to_string e##.type_
  and uuid = e##.uuid in

  try 
    match action with
    | "transpile" -> 
      let res, _, _, _ = Mlts_API.parse_and_translate (Js.to_string e##.code) in
      resolve uuid (Js.string res)
      (*Log.status "compile" Log.Finished ~details:"Files loaded"*)
    | _ -> raise Unknown_action
  
  (* TODO ElpiTODO : Elpi raises various exceptions on file not found for exemple, 
      but we can't catch them without a catch all clause...
      How to get line and character indication, precie error mesage ? *)
    with 
    | Unknown_action -> 
        reject uuid (Js.string "Unknown action")
    | ex ->
        let mess = (Printexc.to_string ex) in
        reject uuid (Js.string  mess)
                 

let _ =
  Printexc.record_backtrace true;
  (* Redirect standard outputs to logging *)
  Sys_js.set_channel_flusher stdout (Log.info ~prefix:"stdout");
  Sys_js.set_channel_flusher stderr (Log.error ~prefix:"stderr");

  Worker.set_onmessage onMessage;
  resolve "start" (Js.string "Elpi started.")

                                                      

                                                    
                                     
