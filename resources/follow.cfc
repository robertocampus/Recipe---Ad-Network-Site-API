<cfcomponent extends="taffyAPI.base" taffy:uri="/follow/" hint="Used to GET recipe made it data from recipe_madeit table.">

	<cffunction name="POST" returntype="Struct" output="false" access="public" auth="true" hint="Add the new follow status for the user">
		<cfargument name="userID" type="numeric" required="true" hint="userID of the user who follows something">
		<cfargument name="auth_token" type="string" required="true" hint="auth_token of the user">
		<cfargument name="entityID" type="numeric" required="true" hint="entityID which user following">
		<cfargument name="entityTypeID" type="numeric" required="true" hint="entityTypeID of entity which user following">
		<cfargument name="followStatus" type="numeric" required="true" hint="value 1 user following the entity">

		<cfset result = structNew() >
		<cfset result['message'] = "" >
		<cfset result['status']  = false >

		<cftry>

			<cfquery name='local.query' datasource="#variables.dataSource#">
				SELECT * FROM users_follow 
					WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
					AND entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
					AND entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
					
			</cfquery>

			<cfif local.query.recordCount NEQ 0 AND local.query.followStatus EQ arguments.followStatus>

				<cfset status = arguments.followStatus EQ 1? application.messages['follow_post_follow_success']:application.messages['follow_post_unfollow_success']>

				<cfset result.message = '#status#'>
				<cfset result.status = true>
				
				<cfreturn representationOf(result).withStatus(200)>


			<cfelseif local.query.recordCount NEQ 0 AND local.query.followStatus NEQ arguments.followStatus>

				<cfquery name="local.query" datasource="#variables.dataSource#">
					
					UPDATE users_follow SET 
						followStatus = <cfqueryparam value="#arguments.followStatus#" cfsqltype="cf_sql_integer">,
						follow_date  = <cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
							WHERE entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
								AND entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
								AND	  userID   = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">

				</cfquery>

				<cfset status = arguments.followStatus EQ 1?application.messages['follow_post_newfollow_success']:application.messages['follow_post_unfollow_success']>


				<cfset result.message = '#status#'>
				<cfset result.status = true>

				<!--- // 9120, 'Success:Follow Records has been updated, 1 --->
				<cfset logAction( actionID = 9120, extra = "method: /follow/POST"  )>
				<cfreturn representationOf(result).withStatus(200)>

			</cfif>

			<cfquery name="local.query" datasource="#variables.datasource#" result="qry">

				INSERT INTO users_follow (
											userID,
											entityID,
											entityTypeID,
											follow_date,
											followStatus
										)	
								values (
											<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">,
											<cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">,
											<cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">,
											<cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">,
											<cfqueryparam value="#arguments.followStatus#" cfsqltype="cf_sql_integer">

										)

			</cfquery>
			<cfset result.id = qry.GENERATED_KEY >

			<cfcatch>	

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /follows/GET" )>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch ) >
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset result.status = true>
		<cfset result.message = application.messages['follow_post_addfollow_success']>
		<!--- // 9121, 'Success: NEW follow record has been added', 1 --->
		<cfset logAction( actionID = 9121, extra = "method: /follows/POST" )>
		<cfreturn representationOf(result).withStatus(200)>

	</cffunction>


	<cffunction name="GET" returntype="Struct" access="public" output="false" hint="To GET the details of user following details" auth="true">

		<cfargument name="userID"  type="numeric" required="true" hint="userID of user who follows something">
		<cfargument name="auth_token" type="string" required="true" hint="auth_token of the user">
		<cfargument name="entityID" type="numeric" required="true" >
		<cfargument name="entityTypeID" type="numeric" required="true">

		<cfset result = structNew()>
		<cfset result['message'] = ''>
		<cfset result['status'] = false>

		<cftry>

			<cfquery name="result.query" datasource="#variables.datasource#">

				SELECT entityID,entityTypeID,follow_date FROM users_follow 
					WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
						AND entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
						AND entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
						AND followStatus = 1

			</cfquery>

			<cfcatch>				
				<!--- // 661, 'Success: follow record has been FOUND', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /follow/GET" )>
				<cfset result.message = errorMessage( message = 'database_query_error')>
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

			<cfif result.query.recordCount EQ 0>

				<cfset result.messsage = application.messages['follow_get_found_error']>
				
				<cfreturn representationOf(result).withStatus(404)>	

			</cfif>

			<cfset result.status  = true>
			<cfset result.message = application.messages['follow_get_found_success']>
			
			<cfset logAction( actionID = 9100, extra = "method: /follow/GET" )>

			<cfreturn representationOf(result).withStatus(200)>

		</cftry>

	</cffunction>

</cfcomponent>