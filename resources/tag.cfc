<cfcomponent extends="taffyAPI.base" taffy_uri="/tag/" hint="Using this user can able to <code>GET</code> tag details" >

	<cffunction name="PUT" access="public" hint="Update Tags" returntype="struct" output="true" auth="true">
		<cfargument name="tags"			type="string" 	required="true" 	hint="Tags List">
		<cfargument name="entityID"		type="numeric" 	required="true"  	hint="entityID">
		<cfargument name="entityTypeID"	type="numeric"  required="true"		hint="entityTypeID">
		<cfargument name="userID"		type="numeric"  required="true"		hint="userID">
		<cfargument name="auth_token"   type="string"	required="true"     hint="auth_token">
	<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] = ''>

		<cftry>
		
		<!--- // remove all tags linked to this blog --->
			<cfquery datasource="#variables.datasource#" name="query">

				DELETE FROM tagging
				WHERE entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_varchar">
				AND entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_varchar">

			</cfquery>	

			<cfloop list="#arguments.tags#" index="thisTag">
				
				<cfquery datasource="#variables.datasource#" name="local.getTag"> 

					SELECT tagID 
					FROM tags
					WHERE tagName = '#thisTag#' 
					LIMIT 0,1

				</cfquery>	
				
				<!--- // START: tag already exists? no --->

				<cfif local.getTag.recordCount EQ 0>	
					
					<cfquery datasource="#variables.datasource#" name="query" result="qry"> 

						INSERT INTO tags ( tagName ) 
						VALUES ( '#thisTag#' )

					</cfquery>
					
					
					<cfset local.tagID = qry.GENERATED_KEY>		
				
				<cfelse>
		 		
					<cfset local.tagID = local.getTag.tagID>	
				
				</cfif>
				<!--- // END: tag already exists? --->
		  	
				<cfquery datasource="#variables.datasource#" name="query"> 

					INSERT INTO tagging ( 
											tagID,
											entityID,
											entityTypeID,
											userID,
											taggingDate 
										)
								VALUES (
											<cfqueryparam value="#local.tagID#" cfsqltype="cf_sql_integer">,
											<cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">,
											<cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">,
											<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">,
											<cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
										)

				</cfquery>
		 		
			</cfloop>	

		 	<cfcatch>

		 		<cfset result.message = errorMessage(message = 'tag_put_update_error', error = variables.cfcatch)>
				<!--- // 93, 'Error: Update Tags', 'Error encountered while updating  tags', 1 --->
				<cfset logAction( actionID = 93,errorCatch = variables.cfcatch, extra = "method: /tag/PUT" )>	
				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch> 

		</cftry>
	   
		<cfset result.status = true />
		<cfset result.message = application.messages['tag_put_update_success']>
		<!--- // 92, 'Tags: Updated', 'User updated  tags', 1 --->
	    <cfset logAction( actionID = 92,extra = "method: /tag/PUT" )>	
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>