<cfcomponent extends="taffyAPI.base" taffy:uri="/dashboard/" hint="user's data for the dashboard action">

	<cffunction name="GET" access="public" returntype="Struct" output="false"  auth="true" hint="GET the users basic details for Dashboard actions">

		<cfargument name="userID" type="numeric" required="true" hint="user ID">
		<cfargument name="auth_token" type="string" required="true" hint="auth_token of the user">
		<cfargument name="filters" type="string" required="false" default="">
		<cfargument name="functionName" type="string" required="true">

		<cfset result=structNew()>
		<cfset result['message'] = "">
		<cfset result['error']   = true>
		<cfset result['status']  = false>

		<cftry>

			<cfswitch expression="#arguments.functionName#">			

				<cfcase value="dashboard_notifications">

					<cfset result['isProfileInComplete'] = 0 >

					<cfquery name="result.query" datasource="#variables.datasource#">

						SELECT 
							dn.notificationid,
							dn.notificationtitle,
							dn.notificationtext,
							dn.notificationIsSticky,
							us.userID
							 FROM dashboard_notifications dn
								LEFT JOIN users_dashboard_stream us 
									ON  us.entityID = dn.notificationID 
									AND us.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
									AND us.entityTypeID = 50 								
								WHERE dn.notificationPublishDate <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" > 
								AND dn.notificationExpireDate >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" > 						
								AND ( 
								       dn.notificationIsSticky = 1 
								       OR us.isClosed IS NULL 
								       OR us.isClosed = 0 
								    )

					</cfquery>	

					<cfquery name="local.getUsers" datasource="#variables.dataSource#">

						SELECT u.userID
						      ,u.isPublisher
						      ,u.userFirstName
						      ,u.userLastName
						      ,u.userGender
						      ,u.userCountryID
						      ,(SELECT max(imageID) FROM images WHERE entityID = u.userID AND entityTypeID = 4)AS 'imageID'

						  FROM users u

						WHERE u.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">

					</cfquery>	

					<cfif local.getUsers.userFirstName EQ '' OR  local.getUsers.userLastName EQ '' OR local.getUsers.userGender EQ '' OR local.getUsers.userGender EQ 0 OR local.getUsers.userCountryID EQ '' OR local.getUsers.userCountryID EQ 1  OR local.getUsers.userCountryID EQ 0 OR local.getUsers.imageID EQ '' OR local.getUsers.imageID EQ 0 >

						<cfset result['isProfileInComplete'] = 1 >

					</cfif>				

					<cfset result['profileStrength'] = application.scoreObj.getInfluencerScore(userID = arguments.userID)>

					<cfset result['message'] = application.messages['dashboard_get_dashboardnotifications_success']>
					<cfset result['error']   = false>
					<cfset result['status']  = true>

					<cfreturn representationOf(result).withStatus(200)>

				</cfcase>


				<cfcase value="dashboard_todos">
					
					<cfquery name="local.query" datasource="#variables.datasource#">

						SELECT 
							dt.todoID,
							dt.toDoTitle,
							dt.toDoText,
							dt.toDoButtonName,
							dt.toDoButtonLink,
							dt.toDoIsSticky,
							dt.toDoIsAllowClose,
							dt.imageID,
							us.userID
							FROM dashboard_todos dt
							LEFT JOIN users_dashboard_stream us 
									ON us.entityID = dt.todoID 
									AND us.entityTypeID = 52 
									AND us.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
							WHERE dt.toDoIsPublished = 1
								AND ( 
								       dt.todoIsSticky = 1 
								       OR us.isClosed IS NULL 
								       OR us.isClosed = 0								       
								    )

					</cfquery>
							
					<cfquery name="local.todo" datasource="#variables.dataSource#">
						
						SELECT u.userID
					       ,u.isPublisher
					       ,u.userFirstName
					       ,u.userLastName
					       ,u.userGender
					       ,u.userCountryID
					       ,u.userPassword
					       ,(SELECT max(imageID) FROM images WHERE entityID = u.userID AND entityTypeID = 4 AND active = 1 )AS 'imageID'
						   ,count(r.recipeID) AS 'totalrecipe' 
						   ,count(ub.blogID) AS 'totalBlogs'
						   ,count(rb.recipeBoxID) AS 'totalBoxRecipes'
						   ,count(uf.id) AS 'totalFollowing'
						   FROM users u

						LEFT JOIN recipes r ON r.userID = u.userID
						LEFT JOIN userblogs ub ON ub.userID = u.userID
						LEFT JOIN recipe_box rb ON rb.userID = u.userID
						LEFT JOIN users_follow uf ON uf.userID = u.userID
						WHERE u.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">

					</cfquery>

					<cfset result.query = queryNew("toDoID,toDoTitle,toDoText,toDoButtonName,toDoButtonLink,toDoIsSticky,toDoIsAllowClose,imageID", "int,varchar,varchar,varchar,varchar,int,int,int")>

					<cfloop query="local.query">					

						<cfif local.todo.totalrecipe LT 1 AND  local.query.todoID EQ 10 >

							<cfset queryAddRow(result.query)>
							<cfset querySetCell( result.query, "toDoID", 			local.query.toDoID ) >
							<cfset querySetCell( result.query, "toDoTitle", 		local.query.toDoTitle ) >
							<cfset querySetCell( result.query, "toDoText", 			local.query.toDoText ) >
							<cfset querySetCell( result.query, "toDoButtonName", 	local.query.toDoButtonName ) >
							<cfset querySetCell( result.query, "toDoButtonLink", 	local.query.toDoButtonLink ) >
							<cfset querySetCell( result.query, "toDoIsSticky", 		local.query.toDoIsSticky ) >
							<cfset querySetCell( result.query, "toDoIsAllowClose", 	local.query.toDoIsAllowClose ) >
							<cfset querySetCell( result.query, "imageID", 			local.query.imageID ) >						

						<cfelseif  local.todo.totalrecipe GTE 10 AND local.todo.totalrecipe LTE 25 AND local.query.todoID EQ 11 >

							<cfset queryAddRow(result.query)>
							<cfset querySetCell( result.query, "toDoID", 			local.query.toDoID ) >
							<cfset querySetCell( result.query, "toDoTitle", 		local.query.toDoTitle ) >
							<cfset querySetCell( result.query, "toDoText", 			local.query.toDoText ) >
							<cfset querySetCell( result.query, "toDoButtonName", 	local.query.toDoButtonName ) >
							<cfset querySetCell( result.query, "toDoButtonLink", 	local.query.toDoButtonLink ) >
							<cfset querySetCell( result.query, "toDoIsSticky", 		local.query.toDoIsSticky ) >
							<cfset querySetCell( result.query, "toDoIsAllowClose", 	local.query.toDoIsAllowClose ) >
							<cfset querySetCell( result.query, "imageID", 			local.query.imageID ) >						

						<cfelseif  local.todo.totalrecipe GT 25 AND local.todo.totalrecipe LTE 50 AND local.query.todoID EQ 12 >

							<cfset queryAddRow(result.query)>
							<cfset querySetCell( result.query, "toDoID", 			local.query.toDoID ) >
							<cfset querySetCell( result.query, "toDoTitle", 		local.query.toDoTitle ) >
							<cfset querySetCell( result.query, "toDoText", 			local.query.toDoText ) >
							<cfset querySetCell( result.query, "toDoButtonName", 	local.query.toDoButtonName ) >
							<cfset querySetCell( result.query, "toDoButtonLink", 	local.query.toDoButtonLink ) >
							<cfset querySetCell( result.query, "toDoIsSticky", 		local.query.toDoIsSticky ) >
							<cfset querySetCell( result.query, "toDoIsAllowClose", 	local.query.toDoIsAllowClose ) >
							<cfset querySetCell( result.query, "imageID", 			local.query.imageID ) >						

						</cfif>

						<cfif local.todo.totalBlogs LT 1 AND local.query.todoID EQ 30 >

							<cfset queryAddRow(	result.query ) >
							<cfset querySetCell( result.query, "toDoID", 			local.query.toDoID ) >
							<cfset querySetCell( result.query, "toDoTitle", 		local.query.toDoTitle ) >
							<cfset querySetCell( result.query, "toDoText", 			local.query.toDoText ) >
							<cfset querySetCell( result.query, "toDoButtonName", 	local.query.toDoButtonName ) >
							<cfset querySetCell( result.query, "toDoButtonLink", 	local.query.toDoButtonLink ) >
							<cfset querySetCell( result.query, "toDoIsSticky", 		local.query.toDoIsSticky ) >
							<cfset querySetCell( result.query, "toDoIsAllowClose", 	local.query.toDoIsAllowClose ) >
							<cfset querySetCell( result.query, "imageID", 			local.query.imageID ) >						

						<cfelseif local.todo.totalBlogs GT 1 AND local.todo.isPublisher NEQ 0 AND local.query.todoID EQ 32 >
							
							<cfset queryAddRow( result.query ) >
							<cfset querySetCell( result.query, "toDoID", 			local.query.toDoID ) >
							<cfset querySetCell( result.query, "toDoTitle", 		local.query.toDoTitle ) >
							<cfset querySetCell( result.query, "toDoText", 			local.query.toDoText ) >
							<cfset querySetCell( result.query, "toDoButtonName", 	local.query.toDoButtonName ) >
							<cfset querySetCell( result.query, "toDoButtonLink", 	local.query.toDoButtonLink ) >
							<cfset querySetCell( result.query, "toDoIsSticky", 		local.query.toDoIsSticky ) >
							<cfset querySetCell( result.query, "toDoIsAllowClose", 	local.query.toDoIsAllowClose ) >
							<cfset querySetCell( result.query, "imageID", 			local.query.imageID ) >						

						<cfelseif local.query.todoID EQ 5 AND (local.todo.userFirstName EQ '' OR  local.todo.userLastName EQ '' OR local.todo.userGender EQ '' OR local.todo.userGender EQ 0 OR local.todo.userCountryID EQ '' OR local.todo.userCountryID EQ 1  OR local.todo.userCountryID EQ 0 OR local.todo.imageID EQ '' OR local.todo.imageID EQ 0 )>

							<cfset queryAddRow( result.query ) >
							<cfset querySetCell( result.query, "toDoID", 			local.query.toDoID ) >
							<cfset querySetCell( result.query, "toDoTitle", 		local.query.toDoTitle ) >
							<cfset querySetCell( result.query, "toDoText", 			local.query.toDoText ) >
							<cfset querySetCell( result.query, "toDoButtonName", 	local.query.toDoButtonName ) >
							<cfset querySetCell( result.query, "toDoButtonLink", 	local.query.toDoButtonLink ) >
							<cfset querySetCell( result.query, "toDoIsSticky", 		local.query.toDoIsSticky ) >
							<cfset querySetCell( result.query, "toDoIsAllowClose", 	local.query.toDoIsAllowClose ) >
							<cfset querySetCell( result.query, "imageID", 			local.query.imageID ) >

						<cfelseif local.query.todoID EQ 2 AND local.todo.userPassword EQ '' >

							<cfset queryAddRow( result.query ) >
							<cfset querySetCell( result.query, "toDoID", 			local.query.toDoID ) >
							<cfset querySetCell( result.query, "toDoTitle", 		local.query.toDoTitle ) >
							<cfset querySetCell( result.query, "toDoText", 			local.query.toDoText ) >
							<cfset querySetCell( result.query, "toDoButtonName", 	local.query.toDoButtonName ) >
							<cfset querySetCell( result.query, "toDoButtonLink", 	local.query.toDoButtonLink ) >
							<cfset querySetCell( result.query, "toDoIsSticky", 		local.query.toDoIsSticky ) >
							<cfset querySetCell( result.query, "toDoIsAllowClose", 	local.query.toDoIsAllowClose ) >
							<cfset querySetCell( result.query, "imageID", 			local.query.imageID ) >	

						</cfif>

					</cfloop>

					<cfset result['profileStrength'] = application.scoreObj.getInfluencerScore(userID = arguments.userID)>

					<cfset result['message'] = application.messages['dashboard_get_dashboardtodos_success']>
					<cfset result['error']   = false>
					<cfset result['status']  = true>

					<cfreturn representationOf(result).withStatus(200)>

				</cfcase>			

			</cfswitch>

			<cfcatch>

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /dashboard/ GET", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>

				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>
		
	</cffunction>	

	<cffunction name="POST" access="public" returntype="Struct" auth="true">
		<cfargument name="userID" 		type="numeric" 	required="true" hint="user ID">
		<cfargument name="auth_token" 	type="string" 	required="true" hint="auth_token of the user">
		<cfargument name="entityID" 	type="array" 	required="true" hint="entityID">
		<cfargument name="entityTypeID" type="numeric" 	required="true" hint="entityTypeID">
		<cfargument name="isViewed" 	type="numeric" 	required="true" hint="isViewed">
		<cfargument name="isResponded" 	type="numeric" 	required="true" hint="isResponsed">
		<cfargument name="isClosed" 	type="numeric" 	required="true" hint="isClosed">

		<cfset result=structNew()>
		<cfset result['message'] = "">
		<cfset result['error']   = true>
		<cfset result['status']  = false>

		<cftry>

			<cfloop array="#arguments.entityID#" index="entityID">

				<cfquery name="local.getTodo" datasource="#variables.dataSource#">
					SELECT 
						*
						FROM users_dashboard_stream
						WHERE
						userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
						AND entityID = <cfqueryparam value="#entityID#" cfsqltype="cf_sql_integer">
						AND entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
				</cfquery>

				<cfif local.getTodo.recordCount EQ 0 >

					<cfquery name = "result.userStream" datasource = "#variables.dataSource#" >
										
						INSERT INTO users_dashboard_stream ( 
												userID,
												entityID,
												entityTypeID,
												isViewed,
												isClosed,
												isResponded 
												) VALUES (
													<cfqueryparam cfsqltype = "cf_sql_numeric"  value = "#arguments.userID#" >,
													<cfqueryparam cfsqltype = "cf_sql_numeric"  value = "#entityID#" >,
													<cfqueryparam cfsqltype = "cf_sql_numeric"  value = "#arguments.entityTypeID#" >,
													<cfqueryparam cfsqltype = "cf_sql_bit" 	 	value = "#arguments.isViewed#" >,
													<cfqueryparam cfsqltype = "cf_sql_bit" 	 	value = "#arguments.isClosed#" >,
													<cfqueryparam cfsqltype = "cf_sql_bit" 		value = "#arguments.isResponded#" >
												)
					</cfquery>

				<cfelse>

					<cfquery name = "result.userStream" datasource = "#variables.dataSource#" >
										
						UPDATE users_dashboard_stream 
							SET
								isViewed = <cfqueryparam cfsqltype = "cf_sql_bit" 	 	value = "#arguments.isViewed#" >,
								isClosed = <cfqueryparam cfsqltype = "cf_sql_bit" 	 	value = "#arguments.isClosed#" >,
								isResponded = <cfqueryparam cfsqltype = "cf_sql_bit" 	value = "#arguments.isResponded#" >
							WHERE
								userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
								AND entityID = <cfqueryparam value="#entityID#" cfsqltype="cf_sql_integer">
								AND entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
												
					</cfquery>

				</cfif>

			</cfloop>

			<cfcatch>

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /dashboard/ POST", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage( message = 'dashboard_post_add_error', error = variables.cfcatch )>
				<cfreturn representationOf( result.message ).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset result['message'] = application.messages['dashboard_post_add_success']>
		<cfset result['error']   = false>
		<cfset result['status']  = true>

		<cfreturn representationOf(result).withStatus(200)>

	</cffunction>

</cfcomponent>