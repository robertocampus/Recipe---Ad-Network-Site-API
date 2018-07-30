<cfcomponent extends="taffy.core.baseSerializer" output="false" hint="Serializer that uses CFML server's json serialization functionality to return json data">

	<cffunction
		name="getAsJson"
		output="false"
		taffy:mime="application/json;text/json"
		taffy:default="true"
		hint="serializes data as JSON">

			<cfscript>				
				// do we have a query response? if so, let's see if there is any records
				if ( isStruct(variables.data) AND structKeyExists(variables.data, "query") ) {
					
					if ( structKeyExists(variables.data, "rows") ) {
						result.total_count = variables.data.rows.total_count;
					}
					
					var extraDataOfResult = listToArray("session_Available,message,status,userID,connectID,importID,recipeID,session_Expiry,auth_token,value_table,total_rows,current_row,sourceURL,totalRecipes,privateRecipes,publishedRecipes,draftRecipes,tags,socialLinks,userMetaDetails,publishers_Meta,sponsorMetaDetails,profileStrength,isProfileInComplete,userSocialDetails,isPasswordNotSet");

					for( fieldName in extraDataOfResult ) {
						if ( structKeyExists(variables.data, fieldName) ) {
							result[fieldName] = variables.data[fieldName];
						}
					}

					var queryFieldNames = listToArray("userUpdateDetails,recipeImportValid,userExperiences,blogSocialDetails,authorBlogDetails,getSiteID,getSiteDailyEarnings_US,getSiteMontlyEarnings_US,getEarningsDetails_US,getSiteDailyEarnings_nonUS,getEarningsDetails_nonUS,getSiteMontlyEarnings_nonUS,reconciledStatus,blowFoldRight");

					for( queryName in queryFieldNames ) {

						if (structKeyExists(variables.data, queryName)){

							result[queryName] = queryToJson(query = variables.data[queryName], type = "text");

						}
					}

					result.dataSet = queryToJson(query = variables.data.query, type = "text");

					/*Adding recipe details to the dataset*/ 

					var recipeDetails = listToArray("recipeDirection,recipeCourses,recipeChannel,recipeCuisines,recipeAllergy,recipeDiets,recipeHolidays,recipeOccasions,recipeSeasons,recipeIngredients");
					
					for( fieldName in recipeDetails ) {
						if ( structKeyExists(variables.data, fieldName) ) {
							structInsert(result.dataSet[1], '#fieldName#',variables.data[fieldName]);
						}
					}

				} else {
					result = variables.data;
				}
			</cfscript>
			
			<cfreturn serializeJSON(result) />
	</cffunction>

	<cffunction name="queryToJson" access="public" hint="Converts query to json for AngularJS and jQuery">
 		<cfargument name="query" 	type="query"  required="true" /> 
 		
 		<!--- :: init result structure --->	
		<cfset var result 		= [] />
		<cfset var local  		= [] />
		
		<cfset var rs = {} />
		<cfset var rs.q = arguments.query />
		<cfset rs.results = [] />
		<cfset rs.columnList = lcase(listSort(rs.q.columnlist, "text" )) />
		
		<cfloop query="rs.q">
			<cfset rs.temp = {} />
			<cfloop list="#rs.columnList#" index="rs.col">
				<cfset rs.temp[rs.col] = rs.q[rs.col][rs.q.currentrow] />
			</cfloop>
			<cfset arrayAppend( rs.results, rs.temp ) />
		</cfloop>
		
		<cfset rs.data = {} />
		<cfset rs.data = rs.results />

		<cfreturn rs.data />
	</cffunction>

</cfcomponent>