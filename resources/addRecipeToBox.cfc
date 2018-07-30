<cfcomponent extends="taffyAPI.base" taffy:uri="/addRecipeToBox/" hint="By using this we can set and get the data to recipes_boxes table">	


	<cffunction name="POST"  access="public" output="false" hint="Used to a add recipe in existing recipeBox data" auth="true">

		<cfargument name="userID" 		type="numeric" 	required="true">
		<cfargument name="auth_token" 	type="string" 	required="true">
		<cfargument name="recipeID" 	type="numeric" 	required="true">
		<cfargument name="recipeBoxID"  type="numeric" 	required="true">
		<cfargument name="orderID" 		type="numeric" 	required="false" default="0">

		<cftry>
			
			<cfset result = structNew() >			

			<cfset result['status']  = false >
			<cfset result['message'] = "" >

			<cfquery name="local.query" datasource="#variables.datasource#" result="insertRecipe">

				INSERT INTO recipes_boxes (
											recipeID
											,recipeBoxID
											,orderID											
											) 
											VALUES (
											<cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">											
											,<cfqueryparam value="#arguments.recipeBoxID#" cfsqltype="cf_sql_integer">
											,<cfqueryparam value="#arguments.orderID#" cfsqltype="cf_sql_integer">
											)

			</cfquery>
			

			<cfcatch>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipes/POST", errorCatch = variables.cfcatch )>
				
				<!--- //OOPS!..There was an erro and recipe was not added to the recipebox.Please try again later. --->
				<cfset result.message = errorMessage(message='addRecipeToBox_post_add_error', error = variables.cfcatch)>

				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch>

		</cftry>
			 

		<cfset result.status  	= true />
		<!--- \\Recipe has been added to the recipe box under this user --->
		<cfset result.message = application.messages['addRecipeToBox_post_add_success']>

	  	<cfset logAction( actionID = 2101, extra = "method: /addRecipeToBox/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>
