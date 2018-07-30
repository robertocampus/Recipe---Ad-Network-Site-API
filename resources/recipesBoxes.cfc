<cfcomponent extends="taffyAPI.base" taffy:uri="/recipesBoxes/" hint="By using this we can get the data from  recipe_box table">

	<cffunction name="GET" access="public" hint="Returns the data from recipe_box table" output="false"  auth="true">
		<cfargument name="userID" 	  type="numeric" required="true"  hint="Current Session UserID.">
		<cfargument name="auth_token" type="string"  required="true"  hint="User authorization token.">		

		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
		

		<cftry>
			
			<cfquery name="result.query" datasource="#variables.datasource#">

				SELECT 	rbx.recipeBoxID
						,rbx.recipeBoxName
						,rbx.recipeBoxCreateDate
						,rbx.recipeBoxUpdateDate
						,rbx.orderID
						,rbx.active
						,img.imageName
						,COUNT(r_map.recipeBoxID) AS recipeCount 
					FROM recipe_box AS rbx
						LEFT JOIN recipes_boxes AS r_map ON rbx.recipeBoxID = r_map.recipeBoxID
						LEFT JOIN images AS img ON rbx.imageID = img.imageID
					WHERE rbx.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
					GROUP BY rbx.recipeBoxID 				

			</cfquery>
			
	
			<cfcatch>

				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipeBox/GET", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />

		  	</cfcatch>
		
  		</cftry>   
		
		<cfset result.status  	= true />
		<cfset result.message = application.messages['recipesboxes_get_found_success'] />

	  	<cfset logAction( actionID = 2108, extra = "method: /recipesBoxes/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="POST"  access="public" output="false" hint="USed to create a new recipeBox data" auth="true">

		<cfargument name="userID" type="numeric" required="true">
		<cfargument name="auth_token" type="string" required="true">
		<cfargument name="recipeBoxName" type="string" required="false" default="">
		<cfargument name="imageID" type="numeric" required="false" default="0">
		<cfargument name="orderID" type="numeric" required="false" default="0">

		<cftry>
			
			<cfset result = structNew() >
			<cfset result['error'] = false >
			<cfset result['errors'] = "" >
			<cfset result['errorsforlog'] = "" >

			<cfset result['status']  = false >
			<cfset result['message'] = "" >

			<cfquery name="local.query" datasource="#variables.datasource#" result="insertRecipe">

				INSERT INTO recipe_box (
										recipeBoxName
										,recipeBoxCreateDate
										,recipeBoxUpdateDate
										,imageID
										,userID
										,orderID
										) 
										VALUES (
										<cfqueryparam value="#arguments.recipeBoxName#" cfsqltype="cf_sql_varchar">
										,<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
										,<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
										,<cfqueryparam value="#arguments.imageID#" cfsqltype="cf_sql_integer">
										,<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
										,<cfqueryparam value="#arguments.orderID#" cfsqltype="cf_sql_integer">
										)

			</cfquery>

			<cfset local.recipeBoxID = insertRecipe.GENERATED_KEY>

			<cfquery name="result.query" datasource="#variables.datasource#">

				SELECT * FROM recipe_box 
					WHERE recipeBoxID = <cfqueryparam value="#local.recipeBoxID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfcatch>

			<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipes/POST", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>
			 

		<cfset result.status  	= true />
		<cfset result.message =application.messages['recipesboxes_post_add_success'] />

	  	<cfset logAction( actionID = 2101, extra = "method: /recipesBoxes/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>
