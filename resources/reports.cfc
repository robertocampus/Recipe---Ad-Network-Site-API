<cfcomponent extends="taffyAPI.base" taffy_uri="/reports/" hint="Using this user can able to <code>GET</code> faq details">

	<cffunction name="POST" access="public" hint="Save Report Blog Record" returntype="struct" output="true">

		<cfargument name="entityID"	     type="string" 	required="true" hint="entityID">
		<cfargument name="entityTypeID"  type="string"  required="true" hint="entityTypeID">
		<cfargument name="reasonID"	 	 type="string" 	required="true" hint="">
		<cfargument name="reportText"    type="string" 	required="false"  default="" hint="Comments from user that filed report">
		<cfargument name="reporterName"  type="string" 	required="false"  default="" hint="Name of user who filed report (optional)">
		<cfargument name="reporterEmail" type="string" 	required="false"  default="" hint="Email of user who filed report (optional)">
		<cfargument name="userID"		 type="numeric" required="false"  default="0" hint="UserID">
  
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message']	= ''>
		
		<cftry> 
			<cfif arguments.entityTypeID EQ "1">

				<cfquery datasource="#variables.datasource#" name="local.query">

					SELECT itemID AS ID,
					itemTitle AS name
					FROM items
					WHERE itemID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.entityID#">

				</cfquery>

			<cfelseif arguments.entityTypeID EQ "2">

				<cfquery datasource="#variables.datasource#" name="local.query">

					SELECT imageID AS ID
					imageName AS name
					FROM images
					WHERE imageID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.entityID#">

				</cfquery>

			<cfelseif arguments.entityTypeID EQ "3">

				<cfquery datasource="#variables.datasource#" name="local.query">

					SELECT blogID AS ID,
					blogTitle AS name 
					FROM blogs
					WHERE blogID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.entityID#">

				</cfquery>
				
			<cfelseif arguments.entityTypeID EQ "4">

				<cfquery datasource="#variables.datasource#" name="local.query">

					SELECT userID AS ID,
					userFirstName AS name
					FROM users
					WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.entityID#">

				</cfquery>

			<cfelseif arguments.entityTypeID EQ "5">

				<cfquery datasource="#variables.datasource#" name="local.query">

					SELECT contestID AS ID,
					contestName AS name
					FROM contests
					WHERE contestID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.entityID#">

				</cfquery>

			<cfelseif arguments.entityTypeID EQ "10">

				<cfquery datasource="#variables.datasource#" name="local.query">

					SELECT recipeID AS ID,
					recipeTitle AS NAME
					FROM recipes
					WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.entityID#">

				</cfquery>

			</cfif>
			
			<!--- // START: Any blogs with this blogID found? --->
			<cfif local.query.recordCount GT 0>
				
				<cfif StructKeyExists(arguments, "userID")>
					<cfset local.userID = arguments.userID>
				<cfelse>
					<cfset local.userID = "">
				</cfif>
	 		
				<cfset local.sendEmail = application.accountObj.sendEmailToAny( 
									
									emailBody = "
				Name: <strong>#arguments.reporterName#</strong><br>
				Email: #arguments.reporterEmail# <a href='mailto:#arguments.reporterEmail#'>(@)</a><br>
				
				Name: <a href='#local.query.Name#'>#local.query.Name#</a><br>
				ID: <strong>#local.query.ID#</strong><br> 
				<br>
				Reason:   <strong>#arguments.reasonID#</strong><br>
				Comments: <strong>#arguments.reportText#</strong>",
									 CC = arguments.reporterEmail,
								 userID = local.userID
								
				)>		
	 		

			</cfif>
			<!--- // END: Any blogs with this blogID found? --->
			
	 		
	  		<cfcatch> 
				
				<cfset result.message = errorMessage( message = 'reports_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 351,  extra = "method:/report/POST", errorCatch = variables.cfcatch)>	
				<cfset representationOf(result.mesage).withStatus(500)>
				
			</cfcatch> 

		</cftry>
 
		<!--- // 372, 'Report: Inserted', 'Report inserted successfully.', 1 --->
		<cfset logAction( actionID = 372,  extra = "method:/report/POST")>	
		
		<cfset result.status = true />
      	<cfset result.message = application.messages['reports_post_add_success']>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>