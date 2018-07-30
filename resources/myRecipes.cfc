<cfcomponent extends="taffyAPI.base" taffy:uri="/myRecipes/" hint="Using this user can able to <code>Get</code> a list of recipe details of a particular User with their userID.">

	<cffunction name="GET" access="public" hint="Returns a <code>LIST</code> of Recipes Data." output="false">

		<cfargument name="userID" 		type="numeric" required="true" hint="Current profile userID">
		<cfargument name="filters" 		type="struct"  default="#StructNew()#" required="false" hint="Recipe Listing Filters struct">		
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['error']   = false />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />		
  
		<cftry>

			<cfset listColumns = 'id, title, source_url, prepare_time, total_time, total_loves, date, level, ratings, cuisine' />
		
			<cfquery datasource="#variables.datasource#" name="result.query"> 
			
				SELECT * FROM (
					SELECT 
						r.recipeID AS 'id',
						r.recipeTitle AS 'title',
						r.recipeSlug AS 'recipeSlug',
						r.recipeSourceURL AS 'source_url',
						r.recipePrepTime AS 'prepare_time',
						r.recipeTotalTime AS 'total_time',
						r.recipeTotalLoves AS 'total_loves',
						r.recipeTotalServings AS 'total_servings',
						r.recipeCreateDate AS 'date',				
						r.recipeRating AS 'ratings',
						v_rd.difficultyName AS 'level',						
						r.isPending AS 'isPending',
						r.isPublished AS 'isPublished',
						r.isprivate AS 'isprivate',
						r.isdraft AS 'isdraft',
						r.islocked AS 'islocked',
						r.recipeStrength,
						(
							SELECT GROUP_CONCAT(DISTINCT(vr_cu.cuisineName) SEPARATOR ',') 
								FROM recipes_cuisine rc
									LEFT JOIN  val_recipe_cuisine vr_cu ON vr_cu.cuisineID = rc.cuisineID
								WHERE rc.recipeID=r.recipeID
						) AS 'cuisine',
						(
							SELECT COUNT(commentID) 
								FROM comments c 
								WHERE c.entityTypeID = 10 									
									AND c.entityID = r.recipeID
									AND c.active  = 1
									AND c.commentStatusID  = 2
						) AS 'total_Comments',
						CONCAT( i.imagePath, '/', i.imageName ) AS 'recipe_FullSize_Image',
						CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'recipe_Thumb_Image',
						CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'recipe_mini_Image',
						( SELECT COUNT(userID) 
							FROM recipe_madeit 
							WHERE recipeID = r.recipeID 
						) AS 'madeIt'

					FROM recipes r

						LEFT JOIN val_recipe_difficulty v_rd ON v_rd.difficultyID = r.recipeDifficulty
						LEFT JOIN images i ON i.entityID = r.recipeID AND i.entitytypeID = 10
						WHERE  r.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
						
					) AS myRecipesData
					
					WHERE 1 = 1 

					<cfloop collection="#arguments.filters#" item="thisFilter">

						<cfif thisFilter EQ "searchText" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND (<cfloop list="#listColumns#" index="thisColumn">
	            					<cfif thisColumn neq listFirst(listColumns)> OR </cfif>

	        					#thisColumn# LIKE "%#trim(arguments.filters[thisFilter])#%"

	            				</cfloop>)

						<cfelseif thisFilter EQ "isprivate" AND TRIM(arguments.filters[thisFilter]) NEQ "">
						
							AND isprivate = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "ispublished" AND TRIM(arguments.filters[thisFilter]) NEQ "">
						
							AND ispublished = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "isdraft" AND TRIM(arguments.filters[thisFilter]) NEQ "">
						
							AND isdraft = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

						</cfif>

					</cfloop>					
					
			</cfquery>
			
			<cfquery name="local.query" datasource="#variables.datasource#">

				SELECT COUNT(recipeID) AS totalRecipes,
				(
					SELECT COUNT(recipeID) 
						FROM recipes 
							WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#"> 
								AND isprivate = 1
				) AS privateRecipes,
				(
				SELECT COUNT(recipeID) 
						FROM recipes 
						WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#"> 
							AND ispublished = 1
				) AS publishedRecipes,
				(
				SELECT COUNT(recipeID) 
						FROM recipes 
							WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#"> 
								AND isdraft = 1
				) AS draftRecipes
				FROM recipes 
					WHERE  userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">

			</cfquery>

			<cfset result.totalRecipes = local.query.totalRecipes>
			<cfset result.privateRecipes = local.query.privateRecipes>
			<cfset result.publishedRecipes = local.query.publishedRecipes>
			<cfset result.draftRecipes = local.query.draftRecipes>

			<cfif result.query.recordCount EQ 0 >
				<cfset result.status  = true />
				<cfset result.message = application.messages['myRecipes_get_found_error'] />
				<cfreturn representationOf(result).withStatus(200)/>
			</cfif>

			<cfcatch>		

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /myRecipes/GET", errorCatch = variables.cfcatch )>
				<cfset result.message =errorMessage( message = 'database_query_error', error = variables.cfcatch )>
				<cfreturn representationOf(result.message).withStatus(500) />	

		  	</cfcatch>
	
  		</cftry>   
		
		<cfset result.status = true />
		<cfset result.message = application.messages["myRecipes_get_found_success"] />

	  	<cfset logAction( actionID = 2004, extra = "method: /myRecipes/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
		
	</cffunction>	


</cfcomponent>