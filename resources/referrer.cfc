<cfcomponent extends="taffyAPI.base" taffy:uri="/referrer/" hint="used to Insert Referrer Record.">

	<cffunction name="POST" access="public" hint="Insert Referrer Record" returntype="struct" output="true">
		<cfargument name="referrerID"		type="string" 	required="yes" hint="User ID of referrer (ReferrerID)">
		<cfargument name="userID"	  		type="string" 	required="yes" hint="User ID of account created">
  	
		<!--- :: init result structure --->	
		<cfset var result		= StructNew() />
		<cfset var local		= StructNew() />
		<cfset result['status']	= false />
  		<cfset result['message'] = ''>

		<cftry>
		
  	
			<!--- 
			<!--- // START: Reset the previous pending thumbnails? --->
			<cfif arguments.blogID NEQ "">
				
				<cfquery datasource="#variables.datasource#" name="local.query">
				UPDATE thumbnails 
					SET active = 0
					WHERE thumbnailStatusID = 1	
				      AND blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#">
				</cfquery>	
			
				<!--- // 1514, 'Thumbnail: Reset Pending', 'Previously pending thumbnails deactivated (reset).', 1 --->
				<cfset logAction( actionID = 1514, user = arguments.user, extra = "method: /referrer/POST" )>	
	 		
			</cfif>
			<!--- // END: Reset the previous pending thumbnails? --->
			--->
			
			<cfquery datasource="#variables.datasource#" name="local.query">

			INSERT INTO referrals 
						( 
							referrerID,
							userID,
							date_referred,
							isApproved,
							isActive
						)
			VALUES  (
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.referrerID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">, 
						<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp" >,
						<cfqueryparam value="0" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="1" cfsqltype="cf_sql_integer">
					
					)

			</cfquery>		
			
			<cfquery datasource="#variables.datasource#" name="local.getLast"> 

				SELECT LAST_INSERT_ID() AS ID

			</cfquery>
	 
			<!--- // 8400, 'Referrer: Inserted', 'Referrer record inserted.', 1 --->
			<cfset logAction( actionID = 8400, extra = "method: /referrer/POST" )>	
			 							
			<cfset result.thumbnailID = local.getLast.ID />	
			<cfset result.status = true />
			<cfset result.message = application.messages['referrer_post_add_success']>	
	   		
	   		
	 		<cfcatch> 

				<cfset result.message = errorMessage( message = 'referrer_post_add_error', error = variables.cfcatch )>
				<!--- // 8401, 'Referrer: Insert Error', 'Error while inserting Referrer record.', 1 --->
				<cfset logAction( actionID = 8401, extra = "method: /referrer/POST", errorCatch = variables.cfcatch )>	
				<cfreturn representationOf( result.message ).withStatus(500)>
				
			</cfcatch> 

		</cftry>
       
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>