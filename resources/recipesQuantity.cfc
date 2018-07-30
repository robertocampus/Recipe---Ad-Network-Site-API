<cfcomponent extends="taffyAPI.base" taffy:uri="/recipeQuantity/" hint="By using this you can get the amount recipe incredients based on your servings">

	<cffunction name="GET" access="public" output="false" hint="get the recipe incredients for your recipe">
		<cfargument name="recipeID" 		type="numeric" required="true" 	hint="RecipeID (Numeric)">
		<cfargument name="noOfServings" 	type="numeric" required="true" 	hint="Total number of servings">
		<cfargument name="standardUnitType" type="string"  required="true" hint="standard Unit used for the conversion">

		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
  

		<cfquery name="local.query" datasource="#variables.datasource#">
			SELECT ra.amountTypeValues, r.recipeTotalServings,r.recipeTotalServings,ru.unitTypeName,ri.ingredientName FROM recipes r
				INNER JOIN recipes_ingredientline ri ON ri.recipeID = r.recipeID
				INNER JOIN val_recipe_unittype ru ON ri.line_unitTypeID = ru.unitTypeID
				INNER JOIN val_recipe_amounttype ra ON ri.line_amountID = ra.amountTypeID
					WHERE	r.recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfif local.query.recordCount EQ 0 >
			<cfset result.message = application.messages['recipe_get_found_error']>
			<cfreturn noData().withStatus(404) />

		<cfelse>
			
			<cfset result.quantity = arrayNew()>

			<cfloop query ="local.query">

				<!--- Get the quantity value for single servings --->
				<cfset forSingleServings = val(amountTypeValues)/recipeTotalServings>
				
				<cfset totalServings = forSingleServings * arguments.noOfServings>
				
				<cfset unitType = unitTypeName >

				<!--- ingredient quantity and the unitType will be stored in this resultIngredients list --->
				<cfset resultIngredients = "" >
				<cfset arrayAppend(result.quantity, ( arguments.standardUnitType EQ "us" ? conversion( totalServings, unitType, resultIngredients ):metricConversion( totalServings, unitType, resultIngredients )) &" || "& ingredientName) >

			</cfloop>

		</cfif>
	
		<cfset result.status = true>
		<cfset result.message = application.messages['recipes_quantity_get_success']>
	  	<cfset logAction( actionID = 2004, extra = "method: /recipesQuantity/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="conversion" access="public" returntype="Any" output="true">
		<cfargument name="totalAmount" 			type="numeric" required="true" >
		<cfargument name="unitType"    			type="string"  required="true" >
		<cfargument name="resultIngredients"    type="string"  required="true" >
		
		<cfscript>
			// Conversion of teaspoon (cut off 3)

			if( arguments.unitType EQ 'tsp' OR arguments.unitType EQ 'teaspoon' ){

				if( arguments.totalAmount GTE 3 ){

					totalTSP = arguments.totalAmount mod 3;

					if( totalTSP ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(totalTSP) & ' tsp');

					}

					totalTBS = arguments.totalAmount / 3;

					return conversion( totalAmount = totalTBS, unitType = 'tbs', resultIngredients = arguments.resultIngredients);

				}else{

					arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(arguments.totalAmount) & ' tsp');

					return arguments.resultIngredients;

				}

			}

			// Conversion of tablespoon (cut off 16)

			if( arguments.unitType EQ 'tbs' OR arguments.unitType EQ 'tablespoon' ){

				if( arguments.totalAmount GTE 16 ){

					totalTBS = arguments.totalAmount mod 16;

					if( totalTBS ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(totalTBS) & ' tbs');

					}

					totalCUP = arguments.totalAmount / 16;

					return conversion( totalAmount = totalCUP, unitType = 'cup', resultIngredients = arguments.resultIngredients);

				}else if( arguments.totalAmount LT 1 ){

					totalTSP = arguments.totalAmount * 3 ;

					return conversion( totalAmount = totalTSP, unitType = 'tsp', resultIngredients = arguments.resultIngredients);

				}else{

					arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(arguments.totalAmount) & ' tbs');

					return arguments.resultIngredients;

				}

			}

			// Conversion of fluid ounce (cut off 8)

			if( arguments.unitType EQ 'floz' OR arguments.unitType EQ 'fl oz' OR arguments.unitType EQ 'fluid ounce' ){

				if( arguments.totalAmount GTE 8 ){

					totalFLOZ = arguments.totalAmount mod 8;

					if( totalFLOZ ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(totalFLOZ) & ' fl oz');

					}

					totalCUP = arguments.totalAmount / 8;

					return conversion( totalAmount = totalCUP, unitType = 'cup', resultIngredients = arguments.resultIngredients);

				}else if( arguments.totalAmount LT 1 ){

					totalTBS = arguments.totalAmount * 2 ;

					return conversion( totalAmount = totalTBS, unitType = 'tbs', resultIngredients = arguments.resultIngredients);

				}else{

					arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(arguments.totalAmount) & ' fl oz');

					return arguments.resultIngredients;

				}

			}

			// Conversion of cup (cut off 2)

			if( arguments.unitType EQ 'cup' OR arguments.unitType EQ 'cups' ){

				if( arguments.totalAmount GTE 2 ){

					totalCUP = arguments.totalAmount mod 2;

					if( totalCUP ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(totalCUP) & ' cup');

					}

					totalPT = arguments.totalAmount / 2;

					return conversion( totalAmount = totalPT, unitType = 'pt', resultIngredients = arguments.resultIngredients);

				}else if( arguments.totalAmount LT 1 ){

					totalTBS = arguments.totalAmount * 8;

					return conversion( totalAmount = totalTBS, unitType = 'fl oz', resultIngredients = arguments.resultIngredients);

				}else{

					arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(arguments.totalAmount) & ' cup');

					return arguments.resultIngredients;

				}

			}
			// Conversion of pt (cut off 2)

			if( arguments.unitType EQ 'pt' OR arguments.unitType EQ 'pts' ){

				if( arguments.totalAmount GTE 2 ){

					totalPT = arguments.totalAmount mod 2;

					if( totalPT ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(totalPT) & ' pt');

					}

					totalQT = arguments.totalAmount / 2;

					return conversion( totalAmount = totalQT, unitType = 'qt', resultIngredients = arguments.resultIngredients);

				}else if( arguments.totalAmount LT 1 ){

					totalCUP = arguments.totalAmount * 2 ;

					return conversion( totalAmount = totalCUP, unitType = 'cup', resultIngredients = arguments.resultIngredients);

				}else{

					arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(arguments.totalAmount) & ' pt');

					return arguments.resultIngredients;

				}

			}

			// Conversion of qt (cut off 4)

			if( arguments.unitType EQ 'qt' OR arguments.unitType EQ 'qts' ){

				if( arguments.totalAmount GTE 4 ){

					totalPT = arguments.totalAmount mod 4;

					if( totalPT ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(totalPT) & ' pt');

					}

					totalGAL = arguments.totalAmount / 4;

					return conversion( totalAmount = totalGAL, unitType = 'gal', resultIngredients = arguments.resultIngredients);

				}else if( arguments.totalAmount LT 1 ){

					totalPT = arguments.totalAmount * 2 ;

					return conversion( totalAmount = totalPT, unitType = 'pt', resultIngredients = arguments.resultIngredients);

				}else{

					arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(arguments.totalAmount) & ' qt');

					return arguments.resultIngredients;

				}

			}

			// Conversion of gallon

			if( arguments.unitType EQ 'gal' OR arguments.unitType EQ 'gallon' ){

				if( arguments.totalAmount GT 1 ){

					arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(arguments.totalAmount) & ' gal');

									

				}else{

					totalQT = arguments.totalAmount * 4 ;

					arguments.resultIngredients = listappend( arguments.resultIngredients ,displayFraction(totalQT) & ' qt');

					// return conversion( totalAmount = totalPT, unitType = 'qt', resultIngredients = arguments.resultIngredients);

				}
				return arguments.resultIngredients;	
			}

			<!--- conversion for unitType dash, drizzle, large, small, medium, pinch, hand, big, box --->
			if( arguments.unitType EQ 'dash' OR arguments.unitType EQ 'drizzle' OR arguments.unitType EQ 'large' OR arguments.unitType EQ 'small' OR arguments.unitType EQ 'medium' OR arguments.unitType EQ 'pinch' OR arguments.unitType EQ 'hand' OR arguments.unitType EQ 'big' OR arguments.unitType EQ 'box'){

				unit = displayFraction(arguments.totalAmount ) &' #arguments.unitType#';
				arguments.resultIngredients = listappend( arguments.resultIngredients ,unit);
				return arguments.resultIngredients;

			}


			<!--- conversion for unitType gram --->
			if( arguments.unitType EQ 'g' OR arguments.unitType EQ 'gram' ){
				
				if( round(arguments.totalAmount) GT 999 ){

					totalGRAM = round(arguments.totalAmount) mod 1000;

					if( totalGRAM ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,totalGRAM & ' g');

					}


					totalKILO =  round(arguments.totalAmount) / 1000;
				
					return conversion( totalAmount = totalKILO, unitType = 'kg', resultIngredients = arguments.resultIngredients);

				}else{

					arguments.resultIngredients = listappend( arguments.resultIngredients ,round(arguments.totalAmount) & ' g');

					return arguments.resultIngredients;

				}
				
			}

			<!--- conversion for unitType kilogram --->
			if (arguments.unitType EQ 'kilogram' OR arguments.unitType EQ 'kg'){

				if( arguments.totalAmount LT 1 ){

					return conversion( totalAmount = arguments.totalAmount * 1000, unitType = 'g', resultIngredients = arguments.resultIngredients);

				}else{

					gram = INT(listlast(numberFormat(arguments.totalAmount,".999"),".") );

					arguments.resultIngredients = listappend( arguments.resultIngredients ,int(arguments.totalAmount) & ' kg');

					if( gram ){

						return conversion( totalAmount = gram, unitType = 'g', resultIngredients = arguments.resultIngredients);

					}

					return arguments.resultIngredients;

				}			

			}

			<!--- conversion for unit-type milliliter --->
			if ( arguments.unitType EQ 'ml' OR arguments.unitType EQ 'milliliter' ){
				
				if( arguments.totalAmount GT 999 ){

					totalML = round(arguments.totalAmount) mod 1000;

					if( totalML ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,totalML & ' ml');

					}

					totalLITRE =  arguments.totalAmount / 1000;
				
					arguments.resultIngredients = listappend( arguments.resultIngredients ,round(totalLITRE) & ' lt');

				}else{

					arguments.resultIngredients = listappend( arguments.resultIngredients ,round(arguments.totalAmount) & ' ml');

				
				}
				return arguments.resultIngredients;
			}

			<!--- conversion for unitType liter --->
			if (arguments.unitType EQ 'liter' OR arguments.unitType EQ 'lt'){

				if( arguments.totalAmount LT 1 ){

					ml = INT(listlast(numberFormat(arguments.totalAmount,".999"),".") );

					arguments.resultIngredients = listappend( arguments.resultIngredients ,ml & ' ml');

				}else{

					ml = INT(listlast(numberFormat(arguments.totalAmount,".999"),".") );

					arguments.resultIngredients = listappend( arguments.resultIngredients ,int(arguments.totalAmount) & ' lt');

					if( ml ){

						arguments.resultIngredients = listappend( arguments.resultIngredients ,ml & ' ml');

					}


				}			
				return arguments.resultIngredients;

			}

		</cfscript>

	</cffunction>

	<!--- Metric Conversion --->

	<cffunction name="metricConversion" returntype="Any" access="public" output="true">
		<cfargument name="totalAmount" 			type="numeric" required="true" >
		<cfargument name="unitType"    			type="string"  required="true" >
		<cfargument name="resultIngredients"    type="string"  required="true" >

		<cfscript>
			
			if( arguments.unitType EQ 'tsp' OR arguments.unitType EQ 'teaspoon' ){

				total_ML = arguments.totalAmount * 5;

				return conversion( totalAmount = total_ML, unitType = 'ml', resultIngredients = arguments.resultIngredients);

			}

			// Conversion of tablespoon 

			if( arguments.unitType EQ 'tbs' OR arguments.unitType EQ 'tablespoon' ){

				total_ML = arguments.totalAmount * 15;

				return conversion( totalAmount = total_ML, unitType = 'ml', resultIngredients = arguments.resultIngredients);

			}

			// Conversion of fluid ounce 

			if( arguments.unitType EQ 'floz' OR arguments.unitType EQ 'fl oz' OR arguments.unitType EQ 'fluid ounce' ){

				total_ML = arguments.totalAmount * 30;

				return conversion( totalAmount = total_ML, unitType = 'ml', resultIngredients = arguments.resultIngredients);

			}

			// Conversion of cup 

			if( arguments.unitType EQ 'cup' OR arguments.unitType EQ 'cups' ){

				total_ML = arguments.totalAmount * 237;

				return conversion( totalAmount = total_ML, unitType = 'ml', resultIngredients = arguments.resultIngredients);

			}

			// Conversion of pt 

			if( arguments.unitType EQ 'pt' OR arguments.unitType EQ 'pts' ){

				total_ML = arguments.totalAmount * 473;

				return conversion( totalAmount = total_ML, unitType = 'ml', resultIngredients = arguments.resultIngredients);

			}

			// Conversion of qt 

			if( arguments.unitType EQ 'qt' OR arguments.unitType EQ 'qts' ){

				total_ML = arguments.totalAmount * 946;

				return conversion( totalAmount = total_ML, unitType = 'ml', resultIngredients = arguments.resultIngredients);

			}

			// Conversion of gallon

			if( arguments.unitType EQ 'gal' OR arguments.unitType EQ 'gallon' ){

				total_LT = arguments.totalAmount * 3.8;

				return conversion( totalAmount = total_LT, unitType = 'lt', resultIngredients = arguments.resultIngredients);

			}

			<!--- conversion for unitType dash, drizzle, large, small, medium, pinch, hand, big, box --->
			if( arguments.unitType EQ 'dash' OR arguments.unitType EQ 'drizzle' OR arguments.unitType EQ 'large' OR arguments.unitType EQ 'small' OR arguments.unitType EQ 'medium' OR arguments.unitType EQ 'pinch' OR arguments.unitType EQ 'hand' OR arguments.unitType EQ 'big' OR arguments.unitType EQ 'box'){

				unit = displayFraction(arguments.totalAmount ) &' #arguments.unitType#';
				arguments.resultIngredients = listappend( arguments.resultIngredients ,unit);
				return arguments.resultIngredients;

			}

			<!--- conversion for unitType gram --->
			if( arguments.unitType EQ 'g' OR arguments.unitType EQ 'gram' ){
				
				return conversion( totalAmount = arguments.totalAmount, unitType = 'g', resultIngredients = arguments.resultIngredients);
				
			}

			<!--- conversion for unitType kilogram --->
			if (arguments.unitType EQ 'kilogram' OR arguments.unitType EQ 'kg'){

				return conversion( totalAmount = arguments.totalAmount, unitType = 'kg', resultIngredients = arguments.resultIngredients);

			}

			<!--- conversion for unit-type milliliter --->
			if ( arguments.unitType EQ 'ml' OR arguments.unitType EQ 'milliliter' ){
				
				return conversion( totalAmount = round(arguments.totalAmount), unitType = 'ml', resultIngredients = arguments.resultIngredients);
				
			}

			<!--- conversion for unitType liter --->
			if (arguments.unitType EQ 'liter' OR arguments.unitType EQ 'lt'){

				return conversion( totalAmount = arguments.totalAmount, unitType = 'lt', resultIngredients = arguments.resultIngredients);

			}

		</cfscript>
		
	</cffunction>

	<!--- converion of decimal value into fraction value --->
	<cffunction name="displayFraction" output="false" access="public" returntype="string" hint="Generates a fraction from a decimal.">
	    <cfargument name="formatThis" type="Numeric" required="true">
	    
	    <cfset wholePart = int(formatThis)>	    
	    <cfset fractionPart = (numberFormat(formatThis,".999") - int(formatThis)) * 100>
	   	
	    <cfif fractionPart NEQ 0>
	        <cfloop from="2" to="100" index="d">
	            <cfif (round(fractionPart * d) MOD 100) EQ 0>
	                <cfset denominator = d>
	                <cfset numerator = round(fractionPart * d) / 100>
	                <cfbreak>
	            </cfif>
	        </cfloop>
	    </cfif>
	    
	    <cfif NOT isDefined("denominator") OR denominator GT 10 >
	    	<cfreturn approximateFraction( arguments.formatThis ) />
	    </cfif>
	    
	    <cfif wholePart GT 0>
	        <cfset fraction = "#wholePart#">
	    <cfelse>
	        <cfset fraction = "">
	   </cfif>
	    
	    <cfif fractionPart NEQ 0>
	        <cfset fraction = fraction &" "&"#numerator#/#denominator#">
	    </cfif>
	    
	    <cfreturn fraction>
	</cffunction>

	<cffunction name="approximateFraction" output="false" access="public" returntype="string" hint="Generates a approximate fraction from a decimal.">
	    <cfargument name="formatThis" type="Numeric" required="true">
	    
	    <cfset wholePart = int(formatThis)>
	    <cfset fractionPart = int((numberFormat(formatThis,".99") - int(formatThis)) * 100)>
	    
	    <cfset predefined = [10,20,30,40,50,60,70,80,90] >
	    

	    <cfloop from = "1" to="#arraylen(predefined)#" index="i" >
	        <cfif fractionPart GT predefined[i]>

	            <cfif predefined[i] EQ 90>
	                <cfset wholePart = wholePart + 1 >
	                <cfset fractionPart = 0 >
	                <cfbreak/>
	            </cfif>

	            <cfif fractionPart LTE predefined[ i + 1 ] >
	                <cfset fractionPart = predefined[ i + 1 ] >
	                <cfbreak/>
	            </cfif>

	        <cfelse>

	        	<cfif fractionPart EQ 0>	                
	                <cfset fractionPart = 0 >
	                <cfbreak/>
	            </cfif>
	            
	            <cfset fractionPart = predefined[ i ] > 
	            <cfbreak/>

	        </cfif>
	    </cfloop>    
	    
	    <cfif fractionPart NEQ 0>
	        <cfloop from="2" to="100" index="d">
	            <cfif (round(fractionPart * d) MOD 100) EQ 0>
	                <cfset denominator = d>
	                <cfset numerator = round(fractionPart * d) / 100>
	                <cfbreak>
	            </cfif>
	        </cfloop>
	    </cfif>
	    
	    <cfif wholePart GT 0>
	        <cfset fraction = "#wholePart#">
	    <cfelse>
	        <cfset fraction = "">
	   </cfif>
	    
	    <cfif fractionPart NEQ 0>
	        <cfset fraction = fraction &" "&"#numerator#/#denominator#">
	    </cfif>
	    
	    <cfreturn fraction>
	</cffunction>

</cfcomponent>