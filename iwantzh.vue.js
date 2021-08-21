
var Tournament = function(json) {
	this.json = json;
}

var header1 = new Vue({
    el: '#header1',
    data: {
        message: 'I Want Crazyhouse!'
    }
});
    var tournaments1 = [];
    var table1 = new Vue({
        el: '#table1',
        data: {
            tournamentsTmp: [],
            tournaments: tournaments1,

            fetches: [
        	    {promise: undefined, loading:false, f: function() { console.log('a'); this.loading = true; return fetchParseSortAndLoadTournamentsOfLichess(
        	    			tournaments1, () => this.loading = false );}},
			    {promise: undefined, loading:false, f: function() { console.log('b'); this.loading = true; return fetchParseSortAndLoadTournamentsForUser(
							"https://lichess.org/api/user/blunderman1/tournament/created",
							tournaments1, () => this.loading = false );}},
			    {promise: undefined, loading:false, f: function() { console.log('d'); this.loading = true; return fetchParseSortAndLoadTournamentsForUser( 
							"https://lichess.org/api/user/TheFinnisher/tournament/created",
							tournaments1, () => this.loading = false );}},
			    {promise: undefined, loading:false, f: function() { console.log('c'); this.loading = true; return fetchParseSortAndLoadTournamentsForUser( 
							"https://lichess.org/api/user/CyberShredder/tournament/created",
							tournaments1, () => this.loading = false );}},
			    {promise: undefined, loading:false, f: function() { console.log('e'); this.loading = true; return fetchParseSortAndLoadTournamentsForUser( 
							"https://lichess.org/api/user/OFBC_Nigeria/tournament/created",
							tournaments1, () => this.loading = false );}},
			    {promise: undefined, loading:false, f: function() { console.log('f'); this.loading = true; return fetchParseSortAndLoadTournamentsForUser( 
							"https://lichess.org/api/user/adet2510/tournament/created",
							tournaments1, () => this.loading = false );}},
			    {promise: undefined, loading:false, f: function() { console.log('g'); this.loading = true; return fetchParseSortAndLoadTournamentsForUser( 
							"https://lichess.org/api/user/ajedrezconzeta/tournament/created",
							tournaments1, () => this.loading = false );}}
        	]
        },
        created: async function() {
        	let this1 = this;
        	
        	let promises = [];
		console.log("test", Promise.any);
        	let maxConcurrentRequests = 2;
        	for (x in this.$data.fetches) {

        		this.$data.fetches[x].promise = this.$data.fetches[x].f();
				promises.push(this.$data.fetches[x].promise);//keep adding until we can
        		if (promises.length == maxConcurrentRequests) {        			
        			//if promises contains max amount of fetch promises we wait for any to finish:
        			console.log('waiting any of these promises to finish: ', promises);
					await Promise.any(promises);
					//at least on of the fetches has finished - lets re-init that array with currently non-finished promises:
					promises = [];
					//if any of the remaining pending promises also finishes while we do this it will be cleaned next loop even if we add it now
					for (y in this.$data.fetches) {
						console.log(">",y,">",this.$data.fetches[y]);
						if (this.$data.fetches[y].loading){
							promises.push(this.$data.fetches[y].promise);
						}
					}
        		}
        		//at this point it is guaranteed promises contains less than maxConcurrentRequests so we can loop again
        	}
        	console.log(promises);
        },
        mounted: function() {
		},
		updated(){
			//alert('Updated hook has been called');
		},
        methods: {
			    moment : moment,
			    colorTournament : function(t){
					if (t.json["createdBy"]=="lichess"){
						return "#bce5dc";
					}
					if (t.json["createdBy"]=="blunderman1"){
						return "#c0e5bc";
					}
					if (t.json["createdBy"]=="thefinnisher"){
						return "#e5bce4";
					}
					if (t.json["createdBy"]=="cybershredder"){
						return "#e5d2bc";
					}
					if (t.json["createdBy"]=="ofbc_nigeria"){
						return "#bccde5";
					}
					if (t.json["createdBy"]=="adet2510"){
						return "#acbdd5";
					}
					if (t.json["createdBy"]=="ajedrezconzeta"){
						return "#d9b3a3";
					}

					return "yellow";	
				}
        }
    });
