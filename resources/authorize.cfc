<cfcomponent extends="taffyAPI.base" taffy:uri="/authorize" hint="methods used to authorize user session">

	<cffunction name="POST" access="public" output="true" hint="Log on User. If user log on Successfully, u can receive auth_token." >
		<cfargument name="userEmail" required="yes" type="string" hint="User Name of existing confirmation user.">
		<cfargument name="password" required="yes" type="string" hint="password of user.">

		<!--- init result structure --->
		<cfset local.qry = "" >
		<cfset var result = StructNew() />

		<cftry>

			<cfquery datasource="#variables.dataSource#" name="result.query" >
				SELECT 	u.userID,
						u.userEmail,
						u.userFirstName,
						u.userLastName,
						u.userName,
						u.isPublisher,
						u.isInfluencer,
						u.isAllowPublisher,
						u.influencerStatusID,
						vi.influencerStatusName,
						vi.influencerStatusDescription,
						u.roleID,
						u.isValidBasicProfile
				FROM
					users AS u LEFT JOIN val_influencerStatus vi ON vi.influencerStatusID = u.influencerStatusID
				WHERE
					  u.active 		= <cfqueryparam value="1" cfsqltype="cf_sql_tinyint" >
				  AND u.userEmail		= <cfqueryparam value="#arguments.userEmail#" cfsqltype="cf_sql_varchar" >
				  AND u.UserPassword 	= <cfqueryparam value="#arguments.password#" cfsqltype="cf_sql_varchar" >
			 	  AND u.isConfirmed 	= <cfqueryparam value="1" cfsqltype="cf_sql_tinyint" >
			</cfquery>

			<!--- // any records? --->
			<cfif result.query.recordCount EQ 1>

				<cfset local.checkUser = read( userID = result.query.userID ) >

				<!--- // explain --->
				<cfif local.checkUser.recordCount EQ 1 AND dateCompare(now(), local.checkUser.sessionExpiry) NEQ -1 >
					<cfset delete( local.checkUser.auth_token ) >
					<cfset local.checkUser = read( userID = result.query.userID ) >
				<cfelse>
					<cfset result.auth_token = local.checkUser.auth_token >
					<cfset result.session_Expiry = local.checkUser.sessionExpiry >
				</cfif>

				<cfif local.checkUser.recordCount NEQ 1 >

					<cfset result.auth_token = createUUID() />
					<cfset result.session_Expiry = dateTimeFormat(dateAdd("h", 24, now()), 'yyyy-mm-dd HH:nn:ss') />

					<!--- // insert auth_token for authenticated user --->
					<cfquery datasource="#variables.dataSource#" name="result.query" result="isInserted">
						INSERT INTO users_authentication (
															userID,
															auth_token,
															IP,
															sessionExpiry
														)
						VALUES (
								<cfqueryparam cfsqltype="cf_sql_integer"	value="#result.query.userID#">,
								<cfqueryparam cfsqltype="cf_sql_varchar" 	value="#result.auth_token#">,
								<cfqueryparam cfsqltype="cf_sql_varchar" 	value="#CGI.REMOTE_ADDR#">,
								<cfqueryparam cfsqltype="cf_sql_timestamp" 	value="#result.session_Expiry#">
								 )
					</cfquery>
				</cfif>

			<cfelse>
				<cfset logAction( actionID = 4, extra = "method: /authorize/POST - username: #arguments.userEmail# - password: #arguments.password#", ip = CGI.REMOTE_ADDR)>
				<cfreturn noData().withStatus(401) />
			</cfif>
			
			<cfcatch>
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 3, extra = "method: /authorize/POST", ip = CGI.REMOTE_ADDR, errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>

	  	<cfset local.logAction = logAction( actionID = 1, extra = "method: /authorize/POST", ip = CGI.REMOTE_ADDR )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>


	<cffunction name="DELETE" access="public" output="false" hint="Log Out.">
		<cfargument name="auth_token" required="true" type="string" hint="Pass user's authentication token as a parameter. It was received after login Successfully.">

		<cfset local.qry = "" >

		<cftry>

			<cfquery datasource="#variables.datasource#" name="local.qry" result="isDeleted">
				DELETE FROM users_authentication
					WHERE auth_token = <cfqueryparam value="#arguments.auth_token#" cfsqltype="cf_sql_varchar">
			</cfquery>

			<cfcatch>

				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				
				<cfset logAction( actionID = 5, extra = "method: /authorize/DELETE", ip = CGI.REMOTE_ADDR, errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset statusCode = ( isDeleted.recordCount GT 0 ) ? 200 : 401 >

		<cfset logAction( actionID = 2, extra = "method: /authorize/DELETE", ip = CGI.REMOTE_ADDR )>

		<cfreturn noData().withStatus(statusCode) />
	</cffunction>


	<cffunction name="GET" access="public" output="true" hint="Check the Login session is available or not for the user.">
		<cfargument name="auth_token" required="true" type="string" hint="The user's authentication token.">
		<cfargument name="userID" required="true" type="numeric" hint="userID of autherized user.">

		<cfset local.qry = "" />
		<cfset result = structNew() />

		<cftry>

			<cfquery datasource="#variables.datasource#" name="local.userDetails">
				SELECT 	ua.*
					FROM users_authentication ua
					WHERE auth_token = <cfqueryparam value="#arguments.auth_token#" cfsqltype="cf_sql_varchar">
						AND ua.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfif local.userDetails.recordCount EQ 1 >

				<cfset result.session_Available = ( dateCompare(now(), local.userDetails.sessionExpiry) EQ -1 ) ? true : false >

				<cfif result.session_Available >

					<cfset local.session_Expiry = dateTimeFormat(dateAdd("h", 24, now()), 'yyyy-mm-dd HH:nn:ss') />

					<cfquery datasource="#variables.datasource#" name="local.qry">
						UPDATE users_authentication
							set
								sessionExpiry = <cfqueryparam value="#local.session_Expiry#" cfsqltype="cf_sql_timestamp">
							WHERE
								userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
					</cfquery>

					<cfset result.query = local.userDetails >

				</cfif>

			<cfelse>

				<cfif structKeyExists(url, "authorize")>
					<cfset result.session_Available = false >
				<cfelse>
					<cfreturn noData().withStatus(401) />
				</cfif>
			</cfif>

			<cfcatch>
				<cfset logAction( actionID = 7, extra = "method: /authorize/GET", ip = CGI.REMOTE_ADDR, errorCatch = variables.cfcatch )>

				<cfreturn noData().withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset logAction( actionID = 6, extra = "method: /authorize/GET", ip = CGI.REMOTE_ADDR )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<!--- Read the authentication of user --->
	<cffunction name="read" returntype="Query" output="true" access="package">

		<cfquery name="local.checkUser" datasource="#variables.datasource#">
			SELECT * FROM users_authentication
			WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfreturn local.checkUser />
	</cffunction>


</cfcomponent>
