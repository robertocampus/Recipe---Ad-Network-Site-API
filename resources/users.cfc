<cfcomponent extends="taffyAPI.base" taffy_uri="/users" hint="users used to get user lists and insert user entry">

	<!--- Method :: GET --->
	<cffunction name="GET" access="public" hint="Return users Listing DATA using filters and pagination" returntype="struct" output="true">
		<cfargument name="filters" 		type="struct" 	default="#StructNew()#" required="no" 	hint="Blog Listing Filters struct">
		<cfargument name="pagination"  	type="struct" 	default="#StructNew()#" required="no" 	hint="Blog Listing pagination struct">
        <cfargument name="cache"   		type="string" 	default="1" 		 	required="no" 	hint="Query Cache Lenght">
		

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />

		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);
		</cfscript>
  		
		<cftry>

			<cfquery datasource="#variables.datasource#" name="result.query"><!--- cachedwithin="#CreateTimeSpan(0,0,15,0)#" --->

			DROP temporary table if exists _tmp_user_search;
			CREATE temporary TABLE _tmp_user_search  (  `userID` INT(10) UNSIGNED NOT NULL,  PRIMARY KEY (`userID`) ) ENGINE=MEMORY;
			
			INSERT INTO _tmp_user_search 
			SELECT userID
			FROM users
			WHERE  ( 	1 = 1

				<!--- ADD FILTERS TO QUERY  --->
				<cfif StructCount(arguments.filters) GT 0>
					
	  				<cfloop collection="#arguments.filters#" item="thisFilter">
					 
						<!--- SEARCH --->	
						<cfif		thisFilter EQ "SearchText" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND userAbout LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#arguments.filters[thisFilter]#%">
								
						<cfelseif	thisFilter EQ "SearchUsername" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND userName = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	
								
						<cfelseif	thisFilter EQ "SearchCountryID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND userCountryID = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">

						<cfelseif	thisFilter EQ "SearchUserEmail" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND userEmail = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">
							
						<!--- <cfelseif	thisFilter EQ "SearchTags" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND blogTags LIKE '%#arguments.filters[thisFilter]#%'--->
												 
						<!--- OTHER FLAGS --->
						<cfelseif	 arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
							AND t.#thisFilter# = #val(arguments.filters[thisFilter])# 
						</cfif>
					
					</cfloop>					
							
				</cfif>					
				
			)
			GROUP BY userID

			<cfif len(arguments.pagination.orderCol) GT 0>ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir#</cfif>;

				SELECT 	SQL_CALC_FOUND_ROWS	
				DISTINCT				
					u.userFirstName
					,u.userLastName					
					,u.userCity					
	 				,c.countryFullName					
					,u.userAbout
					,u.userID
					,u.userEmail
					,GROUP_CONCAT( tg.tagName ) AS tags
					,CONCAT( i.imagePath, '/', i.imageName ) AS 'user_FullSize_Image'
					,CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'user_Thumb_Image'
					,CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'user_mini_Image'
					,(
						SELECT MAX(meta_value)
							FROM users_meta 
						WHERE meta_key = 'users_total_followers' AND userID = u.userID 
					) AS total_followers
					,(
						SELECT MAX(meta_value)
							FROM users_meta 
						WHERE meta_key = 'user_total_posts' AND userID = u.userID 
					) AS total_posts
					,( 
						SELECT COUNT(*) 
							FROM recipes r 
						WHERE r.userID = u.userID
					) AS user_total_recipes
					,u.isValidBasicProfile

				FROM users u
				INNER JOIN ( SELECT userID FROM _tmp_user_search limit #arguments.pagination.offset#, #arguments.pagination.limit# ) t ON t.userID = u.userID

				LEFT JOIN val_countries c on c.countryID = u.userCountryID
				LEFT JOIN val_states s on s.stateID = u.userStateID				
				LEFT JOIN images i ON i.entityID = u.userID AND i.entityTypeID = 4 AND i.active = 1
				LEFT JOIN tagging t ON t.entityID = u.userID AND t.entityTypeID = 4
				LEFT JOIN tags tg ON tg.tagID = t.tagID

				WHERE 1 = 1 
				AND u.active = 1
				GROUP BY u.userID;

			</cfquery>

			<cfquery datasource="#variables.dataSource#" name="result.rows"><!--- cachedwithin="#CreateTimeSpan(0,0,30,0)#" --->
				SELECT FOUND_ROWS()  AS total_count;
			</cfquery>

			<cfif result.rows.total_count EQ 0>
				<cfset result.message = application.messages['users_get_found_error']>
				<cfreturn noData().withStatus(404) />
			</cfif>
			
	 	    <cfcatch>				
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /users/GET", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />		  
			</cfcatch>
		
		</cftry>

		<cfset result.status = true />
	  	<cfset result.message = application.messages['users_get_found_success'] />

	  	<cfset logAction( actionID = 101, extra = "method: /users/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<!--- Method :: POST --->
	<cffunction name="POST" access="public" output="false" returnformat="JSON" returntype="Struct" hint="Return users created DATA details by <code> POST </code> method">		
		<cfargument name="userName" 			required="false"	type="string"	default="" hint="Username (string)" />
		<cfargument name="userEmail" 			required="true"		type="string"	hint="User's Email (string)" />
		<cfargument name="userPassword" 		required="false"	type="string"	default=""  hint="User's Password (string)" />
		<cfargument name="userNameStatus" 		required="false"	type="numeric"	default="0" hint="" />
		<cfargument name="userFirstName" 		required="false"	type="string"	default=""  hint="User's First name (string)" />
		<cfargument name="userLastName" 		required="false"	type="string"	default=""  hint="User's Last name (string)"/>		
		<cfargument name="userGender" 			required="false"	type="string"	default=""  hint="User's Gender (string)" />
		<cfargument name="userAddressLine1" 	required="false"	type="string"	default=""  hint="User's Address (string)" />
		<cfargument name="userAddressLine2" 	required="false"	type="string"	default="" />
		<cfargument name="userAddressLine3" 	required="false"	type="string"	default="" />
		<cfargument name="userCity" 			required="false"	type="string"	default="" />
		<cfargument name="userStateID" 			required="false"	type="string"	default="0" />
		<cfargument name="userZip" 				required="false"	type="string"	default="" />
		<cfargument name="userCountryID" 		required="false"	type="numeric"	default="1" />
		<cfargument name="userPhone1" 			required="false"	type="string"	default="" />
		<cfargument name="userPhone1Ext" 		required="false"	type="string"	default="" />
		<cfargument name="userPhone2" 			required="false"	type="string"	default="" />
		<cfargument name="userPhone2Ext" 		required="false"	type="string"	default="" />
		<cfargument name="userPhone3" 			required="false"	type="string"	default="" />
		<cfargument name="userPhone3Ext" 		required="false"	type="string"	default="" />
		<cfargument name="userAbout" 			required="false"	type="string"	default="" />
		<cfargument name="userDateBirth" 		required="false"	type="any"		default="" />
		<cfargument name="locationID" 			required="false"	type="numeric"	default="0" />
		<cfargument name="timeZoneID" 			required="false"	type="numeric"	default="0" />
		<cfargument name="active" 				required="false"	type="numeric"	default="1" />
		<cfargument name="userPasswordReminder" required="false"	type="string"	default="" />
		<cfargument name="userPasswordQuestion" required="false"	type="string"	default="" />
		<cfargument name="roleID" 				required="false"	type="numeric"	default="1" />
		<cfargument name="isAllowPublisher" 	required="false"	type="numeric"	default="1" />
		<cfargument name="isPublisher" 			required="false"	type="numeric"	default="0" />
		<cfargument name="publisherID" 			required="false"	type="numeric"	default="0" />
		<cfargument name="userConfirmationCode" required="false"	type="string"	default="" />
		<cfargument name="userDateConfirmed" 	required="false"	type="any"		default="" />
		<cfargument name="isConfirmed" 			required="false"	type="numeric"	default="0" />
		<cfargument name="isUserEmailBounced" 	required="false"	type="numeric"	default="1" />
		<cfargument name="isUserMarkedAsSpam" 	required="false"	type="numeric"	default="0" />
		<cfargument name="referrerEnrolledDate" required="false"	type="any"		default="" />
		<cfargument name="referrerRejectedDate" required="false"	type="any"		default="" />
		<cfargument name="referrerAppliedDate" 	required="false"	type="any"		default="" />
		<cfargument name="referrerOptedOutDate" required="false"	type="any"		default="" />
		<cfargument name="referrerCommission" 	required="false"	type="numeric"	default="10" />
		<cfargument name="isReferrerEnabled" 	required="false"	type="boolean" 	default="0" />
		<cfargument name="referrerStatusID" 	required="false"	type="string"	default="" />
		<cfargument name="userImageID"			required="false"    type="numeric"   default="0">
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result.status  	= false />
		<cfset result.message 	= "" />
		<cftry>			

			<cfquery name="result.query" datasource="#variables.datasource#" result="qry">
				INSERT INTO users (
					userName
					,userNameStatus
					,userEmail
					,userFirstName
					,userLastName
					,userPassword
					,userDateRegistered
					,userDateLastLogin					
					,userGender
					,userAddressLine1
					,userAddressLine2
					,userAddressLine3
					,userCity
					,userStateID
					,userZip
					,userCountryID
					,userPhone1
					,userPhone1Ext
					,userPhone2
					,userPhone2Ext
					,userPhone3
					,userPhone3Ext
					,userAbout
					,userDateBirth
					,locationID
					,timeZoneID
					,active
					,userPasswordReminder
					,userPasswordQuestion
					,roleID
					,isAllowPublisher
					,isPublisher
					,publisherID
					,userConfirmationCode
					,userDateConfirmed
					,isConfirmed
					,isUserEmailBounced
					,isUserMarkedAsSpam
					,referrerEnrolledDate
					,referrerRejectedDate
					,referrerAppliedDate
					,referrerOptedOutDate
					,referrerCommission
					,isReferrerEnabled
					,referrerStatusID
					,isValidBasicProfile
					
				) 
				VALUES (
					<cfqueryparam value="#arguments.userName#"				cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userNameStatus#"		cfsqltype="cf_sql_tinyint" 	/>
					,<cfqueryparam value="#arguments.userEmail#"			cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userFirstName#"		cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userLastName#"			cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userPassword#"			cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp" >
					,<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp" >					
					,<cfqueryparam value="#arguments.userGender#"			cfsqltype="cf_sql_char"	/>
					,<cfqueryparam value="#arguments.userAddressLine1#"		cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userAddressLine2#"		cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userAddressLine3#"		cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userCity#"				cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userStateID#"			cfsqltype="cf_sql_varchar" 	/>
					,<cfqueryparam value="#arguments.userZip#"				cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userCountryID#"		cfsqltype="cf_sql_integer"	/>
					,<cfqueryparam value="#arguments.userPhone1#"			cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userPhone1Ext#"		cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userPhone2#"			cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userPhone2Ext#"		cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userPhone3#"			cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userPhone3Ext#"		cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userAbout#"			cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userDateBirth#"		cfsqltype="cf_sql_timestamp"	/>
					,<cfqueryparam value="#arguments.locationID#"			cfsqltype="cf_sql_tinyint" 	/>
					,<cfqueryparam value="#arguments.timeZoneID#"			cfsqltype="cf_sql_integer" 	/>
					,<cfqueryparam value="#arguments.active#"				cfsqltype="cf_sql_integer" 	/>
					,<cfqueryparam value="#arguments.userPasswordReminder#"	cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userPasswordQuestion#"	cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.roleID#"				cfsqltype="cf_sql_integer" 	/>
					,<cfqueryparam value="#arguments.isAllowPublisher#"		cfsqltype="cf_sql_integer" 	/>
					,<cfqueryparam value="#arguments.isPublisher#"			cfsqltype="cf_sql_integer" 	/>
					,<cfqueryparam value="#arguments.publisherID#"			cfsqltype="cf_sql_integer" 	/>
					,<cfqueryparam value="#arguments.userConfirmationCode#"	cfsqltype="cf_sql_varchar"	/>
					,<cfqueryparam value="#arguments.userDateConfirmed#"	cfsqltype="cf_sql_timestamp"	/>
					,<cfqueryparam value="#arguments.isConfirmed#"			cfsqltype="cf_sql_tinyint" 	/>
					,<cfqueryparam value="#arguments.isUserEmailBounced#"	cfsqltype="cf_sql_tinyint" 	/>
					,<cfqueryparam value="#arguments.isUserMarkedAsSpam#"	cfsqltype="cf_sql_tinyint" 	/>
					,<cfqueryparam value="#arguments.referrerEnrolledDate#"	cfsqltype="cf_sql_timestamp"	/>
					,<cfqueryparam value="#arguments.referrerRejectedDate#"	cfsqltype="cf_sql_timestamp"	/>
					,<cfqueryparam value="#arguments.referrerAppliedDate#"	cfsqltype="cf_sql_timestamp"	/>
					,<cfqueryparam value="#arguments.referrerOptedOutDate#"	cfsqltype="cf_sql_timestamp"	/>
					,<cfqueryparam value="#arguments.referrerCommission#"	cfsqltype="cf_sql_integer" 	/>
					,<cfqueryparam value="#arguments.isReferrerEnabled#"	cfsqltype="cf_sql_bit"	/>
					,<cfqueryparam value="#arguments.referrerStatusID#"		cfsqltype="cf_sql_varchar"	/>

					<cfif len(arguments.userFirstName) AND len(arguments.userLastName) AND len(arguments.userGender) AND len(arguments.userImageID) AND arguments.userImageID NEQ 0>
						,<cfqueryparam value="1" cfsqltype="cf_sql_integer">
					<cfelse>
						,<cfqueryparam value="0" cfsqltype="cf_sql_integer">
					</cfif>

				)
			</cfquery>


			<cfquery name="result.query" datasource="#variables.datasource#">
				SELECT * FROM users
				WHERE userID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer">
			</cfquery>
				
			<cfcatch>						
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /users/POST", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />		  
			</cfcatch>
			
		</cftry>

		<cfset result.status = true />
		<cfset result.message = application.messages['users_post_addnewuser_success'] />

	  	<cfset logAction( actionID = 100, extra = "method: /users/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>