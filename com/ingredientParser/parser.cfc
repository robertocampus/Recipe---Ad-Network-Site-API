<cfcomponent>

<cfset inflectorObj = createObject("component","Inflector")>


<cffunction name="unitsOfMeasure" output="false" access="public" description="Parse a string">
    <cftry>
        
        <cfscript>
            module.exports = {};

            module.exports.reOptional = "(optional|\(\W*optional\W*\)$)";

            module.exports.unitsOfMeasure = {
                tablespoon: ['T', 'Tb', 'tb'],
                teaspoon: ['t', 'Tsp', 'tsp'],
                cup: ['C', 'c'],
                pint: ['pt', 'PT', 'Pt'],
                quart: ['QT', 'Qt', 'qt'],
                pinch: [],
                little: [],
                dash: [],
                drizzle: [],
                gallon: ['Gal', 'GAL', 'gal'],
                ounce: ['oz', 'Oz', 'OZ'],
                milliliter: ['ml'],
                liter: ['L', 'l','lt','lit','Lt'],
                inch: ['"', 'in', 'In', 'IN'],
                millimeter: ['mm'],
                centimeter: ['cm'],
                whole: [],
                half: [],
                can: [],
                bottle: [],
                clove : ['cl'],          
                large: ['lg', 'LG', 'Lg'],
                'package': ['pkg', 'Pkg', 'PKG'],
                pound: ['lb', 'Lb', 'LB'],
                kilogram:['kg','Kgs'],
                gram:['g'],
                hand:['hand'],
                large:['large'],
                small:['small'],
                big:['big'],
                medium:['medium'],
                box:[],
                'fl oz':[],
                oz:['oz','ounce']

            };

            module.exports.fluidicWords = [
                'fluid', 'fl'
            ];
            
            module.exports.reToWords = "/ *(to([ 0-9]+)|- *)/i";

            module.exports.noiseWords = [
                'a', 'of'
            ];
           
            return module.exports;
        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>

    </cftry>

</cffunction>

<cffunction name="ParserUnits" returntype="Any" access="public" output="false">
    <cftry>
      
        <cfscript>
       
            var rtn = {};
            var options = {};   
            var unitsTable = {};
            var expandedUnits = [];
            
            Defaults = this.unitsOfMeasure();
            
            var unitsKeys = structKeyArray(unitsOfMeasure);
            var unitsOfMeasure = Defaults.unitsOfMeasure;    

        </cfscript>

        <cfloop collection="#unitsOfMeasure#" item="key">
        
            <cfset #ArrayAppend(expandedUnits, unitsOfMeasure[key] ,true)#>

            <cfloop array="#unitsOfMeasure[key]#" index="alt">

                <cfset unitsTable[alt] = key>

            </cfloop>

        </cfloop>



        <cfscript>
            rtn.options = options;
            rtn.unitsTable = unitsTable;
            rtn.expandedUnits = expandedUnits;
            rtn.unitsOfMeasure = unitsOfMeasure;
            return rtn;
        </cfscript>

        <cfcatch>

            <cfset ing.result = false>
            <cfreturn ing>

        </cfcatch>

    </cftry>

</cffunction>

<cffunction name="getAmount" returntype="Any" access="public" >
    <cfargument name="from" type="any" required="true" >
    <cftry>
        
        <cfscript>  
            

                var s = arrayToList( arguments.from, ' ');
                var start = listFirst(arrayToList(reMatch('(\d+\W\d+\/\d+|\d+\/\d+|\d+\.\d+|\d+)',s), ' '),' ');
                
                 if ( len(start) AND ListFindNoCase( s ,listGetAt( start, 1, ' '), ' ' ) EQ 0){
                       s= replace(s, start, start&' ');
                 }


                for ( i=1; i <= listLen(start, ' '); i++ ){            

                    s = ListDeleteAt( s , 
                                        ListFindNoCase( s , 
                                            listGetAt( start, i, ' '), 
                                        ' ' ), 
                                    ' ');
                    
                }

                

                return {
                    match: start,
                    rest: listToArray( s, ' ')
                };
                
        </cfscript>
        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>
    </cftry>

</cffunction>


<cffunction name="getFluidic" returntype="Any" access="public" >
    <cfargument name="from" type="any" required="true" >
    <cftry>
        
        <cfscript>
     

            var fluidicwords = arraytolist(this.unitsOfMeasure().fluidicwords);
            var lVal = Lcase(arguments.from[1]);

            if(find(lVal, "\.") EQ 0){
                replace(lval,"\.",'');
            }

            if (Listfind(fluidicwords,lval,",") > 0){
                return true;
            }
         
            return false;

       
        </cfscript>
        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>

    </cftry>

</cffunction>

<cffunction name="checkForMatch" returntype="Any" access="public">
    <cfargument name="len"     type="any" required="true">
    <cfargument name="section" type="any" required="true">
    <cfargument name="within"  type="any" required="true">
    <cfargument name="offset"  type="any" required="true">
    <cftry>
        
        <cfscript>
           

            if(arrayLen(arguments.within)-offset lt arguments.len){
                return false;
            }
          
            var arraySlice = arraySlice(arguments.within,arguments.offset+1,arguments.len);
            var arrayList =lcase(arraytolist(arraySlice," "));

            if(Compare(arrayList, arguments.section) eq 0){
                return offset;
            }
            

            result = checkForMatch(len, section, within, offset+1);

            return result;


        </cfscript>
        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>
    </cftry>
</cffunction>

<cffunction name="findMatch" returntype="Any" access="public">
    <cfargument name="from" type="any" required="true" >

    <cftry>
        
        <cfscript>
     
            matchList = arguments.from.lookfor;
            matchIdx = checkForMatch(arrayLen(matchList),arrayToList(matchList, " "),arguments.from.within,0);
        
            if(isNumeric(matchIdx)){
              
                matchIdx = matchIdx+1;

                for( i=1 ; i <= arrayLen(matchList); i++) {

                    arrayDeleteAt(arguments.from.within,matchIdx);

                }

            }
       
            return matchIdx;

        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>

    </cftry>

</cffunction>

<cffunction name="getALittle" returntype="Any" access="public" >
    <cfargument name="from" type="any" required="true" >
    <cftry>
        
        <cfscript>    

            var idx = this.findMatch({
                lookFor: ['a', 'little'],
                within: arguments.from
            });

            return idx==false?false:true;
          
        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>

    </cftry>

</cffunction>

<cffunction name="getUnit" returntype="Any" access="public" >
    <cfargument name="from" type="any" required="true" >
    <cftry>
       
        <cfscript>  
            if(this.getALittle(from)){
                return 'a little';
            }

            if(this.isUnitOfMeasure(arguments.from[1])){

                return this.unitExpander(arguments.from[1]);
            }
            return false;
          
        </cfscript>
        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>
    </cftry>

</cffunction>

<cffunction name="isUnitOfMeasure" returntype="Any" access="public" >
    <cfargument name="value" type="any" required="true" >
    <cftry>
        
        <cfscript>        
            var val = lcase(inflectorObj.singularise(arguments.value));
            var unitsOfMeasure = this.unitsOfMeasure().unitsOfMeasure;
            var expandedUnits = this.ParserUnits().expandedUnits;
          
        
        if(structKeyExists(unitsOfMeasure,val) || ArrayFind(expandedUnits, val) > 0 ){ 
            return true;
        }
        return false;
           
       
          
        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>

    </cftry>


</cffunction>

<cffunction name="unitExpander" returntype="Any" access="public" >
    <cfargument name="unit" type="any" required="true" >
    <cftry>
        
        <cfscript>     
          
            var Lval = lcase(inflectorObj.singularise(arguments.unit));
            var unitsTable = this.ParserUnits().unitsTable;
         
            if(structKeyExists(unitsTable, Lval)){
                Lval = this.properCase( StructFind(unitsTable, Lval) ); 
            }else{
                Lval = this.properCase(Lval);
            }
            return Lval;
          
        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>

    </cftry>

</cffunction>

<cffunction name="properCase" returntype="Any" access="public" >
    <cfargument name="unit" type="any" required="true" >
    <cftry>
        
        <cfscript>
            var val = arguments.unit;
            var result = ucase(Left(val, 1))& lcase(right(val,len(val)-1));
            return result;
        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>
    </cftry>

</cffunction>

<cffunction name="getByWeight" returntype="Any" access="public">
    <cfargument name="from" type="any" required="true">

    <cfscript>
        var idx = this.findMatch({
        lookFor: ['by', 'weight'],
        within: from
        });

        return idx==false?false:true;
    </cfscript>
</cffunction>

<cffunction name="getOptional" returntype="Any" access="public">
    <cfargument name="from" type="any" required="true">
    <cfargument name="res" type="any" required="false" default="false">

    <cftry>
        
        <cfscript>
            var options = ParserUnits().options;
            var Defaults = unitsOfMeasure();

            if(structKeyExists(options, "reOptional")){
                var reOptional = options.reOptional;
            }else{
                var reOptional = Defaults.reOptional;
            }
            for(var i=1; i<=arrayLen(arguments.from); i++){

                if(REfind(reOptional, arguments.from[i])){
                    arguments.res = true;
                    arrayDeleteAt(arguments.from, i);
                }
            }
            return arguments;
        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>
    </cftry>

</cffunction>

<cffunction name="getToTaste" returntype="Any" access="public">
    <cfargument name="from" type="any" required="true">
    <cftry>
        
        <cfscript>
            var idx = this.findMatch({
            lookFor: ['to', 'taste'],
            within: from
            });

            return idx==false?false:true;
        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>

    </cftry>
</cffunction>

<cffunction name="getPrep" returntype="Any" access="public">
    <cfargument name="from" type="any" required="true">
    <cftry>
        
        <cfscript>

            var result = {};
            var start = false;
            var inPrep = false;
            result.check = false;
            result.from = arguments.from;

            for(idx = 1; idx<=arrayLen(result.from); idx++){   

                if((!inPrep) && (start == false) && left(result.from[idx], 1)=='('){
                    inPrep = true;
                    start = idx;
                }
                if(inPrep && (right(result.from[idx], 1)==')')){
                    inPrep = false;
                    end = idx;
                }
            }

            if(start != false){    

                prepList = arrayToList(result.from, ' ');
         
                for( i=start ; i <= end; i++){     
                    arrayDelete(result.from,listGetAt(prepList,i,' '));
                }
        
                result.check = true;

            }
       
            return result;

        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>
    </cftry>

</cffunction>

<cffunction name="removeNoise" returntype="Any" access="public">
    <cfargument name="from" type="any" required="true">
    <cftry>
        
        <cfscript>
            var value = arguments.from;
            var noise = this.unitsOfMeasure().noisewords;
            var result = [];

            for(i=1; i<=arraylen(noise);i++){
                if(ArrayFind(value,noise[i]) > 0 ){
                    arrayAppend(result,ArrayFind(value,noise[i]));
                }
            }

            if(ArrayIsEmpty(result)){
                return false;
            }else{
                return result;
            }

        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>

        </cfcatch>

    </cftry>
</cffunction>

<cffunction name="parse" returntype="Any" access="public" output="true">
    <cfargument name="source" type="any" required="true" >
    <cftry>
        
        <cfscript>
            
            var parts = listToArray(arguments.source,' ',false,true);
            var ing = {};
            ing.result = false;
            var val = {};
            var tmpAmount = '';

            if( parts[1] EQ 'a' ){
                tmpAmount = 1;
                ArraydeleteAt(parts,1);
            }
            
            if( parts[1] EQ 'little'){
                ArraydeleteAt(parts,1);
            }

            if( parts[1] EQ 'couple'){
                tmpAmount = 2;
                ArraydeleteAt(parts,1);
            }

            val = this.getAmount(parts);        
            
            if( NOT tmpAmount NEQ '' AND NOT StructIsEmpty(val)){
                ing.amount = val.match;
                parts = val.rest;
            }

            if(this.getFluidic(parts)){
                ArraydeleteAt(parts,1);
                ing.fluidic = true;
            }
           
            val.unit = this.getUnit(parts);

            
            if(val.unit NEQ "" AND val.unit NEQ false){
                
                ing.unit = val.unit;
                
                if(ing.unit EQ "a little"){

                    for( i=1 ; i <= 2; i++) {
                        arrayDeleteAt(parts,1);
                    }

                }else{

                    ArraydeleteAt(parts,1);

                }
            }
            
           
            if(this.getByWeight(parts)){
              
                ing.byWeight = true;

                for( i=1 ; i <= 2; i++) {
                    arrayDeleteAt(parts,1);
                }

            }

            if(this.getOptional(parts).res){
                parts = this.getOptional(parts).from;
                ing.optional = true;
            }

            if(this.getToTaste(parts)){
                
                ing.toTaste = true;

                for( i=1 ; i <= 2; i++) {
                    arrayDeleteAt(parts,1);
                }

            }
           
            if(this.getPrep(parts).check){

                parts = this.getPrep(parts).from;

            }

            if(isarray(this.removeNoise(parts))){
                
                var index = this.removeNoise(parts);

                for(i=1;i<=arraylen(index);i++){
                    arrayDeleteAt(parts, index[i]);
                }

            }

            ing.name = arraytolist( parts, ' ');

            if(tmpAmount NEQ ""){
                
                if( ing.unit NEQ 'Little' ){

                    ing.amount = tmpAmount;
                    
              }
            }
            ing.result = true;
            return ing; 

        </cfscript>

        <cfcatch>
            <cfset ing.result = false>
            <cfreturn ing>
        </cfcatch>

    </cftry>
    
</cffunction>

</cfcomponent>