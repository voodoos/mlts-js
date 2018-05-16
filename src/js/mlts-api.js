/**
 * @file Mlts-api
 * This file provide a small api to communicate
 * with mlts-worker to transpile mlts programs
 * into lambda-prolog programs
 *
 */

// Stolen somewhere...
function generateUUID() { // Public Domain/MIT
  var d = new Date().getTime();
  if (typeof performance !== 'undefined' && typeof performance.now === 'function') {
    d += performance.now(); //use high-precision timer if available
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    var r = (d + Math.random() * 16) % 16 | 0;
    d = Math.floor(d / 16);
    return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
  });
}

/**
 *  The main class, handling the lifecycle of
 * the Mlts Worker. 
 * 
 * */
class Mlts {
  /**
   * Creates a worker.
   * 
   * @callback loggerCB
   *    @param {string} lvl 
   *       The log level (Info, Warning or Error).
   *    @param {string} prefix
   *       The prefix, "who" sent the message.
   *    @param {string} text
   *       The text of the message
   *  The callback used when the Worker asks for logging
   * 
   */
  constructor(loggerCB) {
    this.worker = null;

    this.logger = loggerCB;

    /* We cannot send directly callbacks to the worker
     * because functions are not clonable.
     * We store the callbacks for our promises
     * with a unique id and send the id to the worker. 
     * When the worker finishes its work it sends back 
     * the id and the callback is called.
     */
    this.resolves = [];
    this.rejects = [];


    var that = this;
    /* Message from the Elpi worker are 
    treated by the following function */
    this.onmessage = function (event) {
      var d = event.data;
      switch (d.type) {
        case "log":
          loggerCB(d.lvl, d.prefix, d.text);
          break;
        case "resolve":
          /* If it's a promise resolving, we use the id 
           * to call the correct callback */
          that.resolves[d.uuid](d.value);
          delete that.resolves[d.uuid];
          delete that.rejects[d.uuid];
          break;
        case "reject":
          /* If it's a promise rejection, we use the id 
          * to call the correct callback */
          that.rejects[d.uuid](new Error(d.value));
          delete that.resolves[d.uuid];
          delete that.rejects[d.uuid];
          break;
      }
    }

    /* The start property will store the promise
     * resolved at the end of the starting process */
    this.start = this.startMlts();
  }

  /**
   * Starts the Mlts Worker
   * It must be in the same folder.
   * 
   * Returns a promise which is stored 
   * in the start property.
   * 
   * @returns {Promise}
   */
  startMlts() {
    this.worker = new Worker("mlts-worker.js");
    this.worker.onmessage = this.onmessage;

    var that = this;

    return new Promise(function (resolve, reject) {
      // save callbacks for later
      that.resolves["start"] = resolve
      that.rejects["start"] = reject
    })
  }

  registerPromise(uuid, message) {
    var that = this;
    return new Promise(function (resolve, reject) {
      // save callbacks for later
      that.resolves[uuid] = resolve
      that.rejects[uuid] = reject

      that.worker.postMessage(message);
    })
  }

  /**
   * Sends some files for compilation to the Worker.
   * It returns a promise.
   * At the end of the execution the worker will resolve
   * the promise with the resulting lprolog program object :
   * { prog: string, types: string, typesEval: string }

   * Or reject it with an error message.
   * 
   * @param {array({name: string, content: string})} files
   *   An array of files. Files are describded using two
   * strings: the name of the file and its content.
   *   All files in the array will be compiled and ready
   * to be queried (if no errors where found)
   * 
   * @returns {Promise}
   */
  transpile(code) {
    var uuid = generateUUID();
    var message = { type: "transpile", code, uuid };

    return this.registerPromise(uuid, message)
  }

  kill() {
    this.worker.terminate();
    /* We need to reject all non-resolved promises */

    var that = this
    Object.keys(this.rejects).forEach(function (r) {
      that.rejects[r](new Error("Mlts restarted or stopped."));
    });
    this.resolves = [];
    this.rejects = [];
  }

  /**
   * Stop and restart the Mlts Worker
   * 
   * Returns a promise which is stored 
   * in the start property.
   * 
   * @returns {Promise}
   */
  restart() {
    this.kill();

    return (this.start = this.startMlts());
  }

}

export default Mlts;