<!--- PUT and DELETE methods in this component requires super-user authentication (admin) --->

<cfcomponent extends="TaffyAPI.base" taffy_uri="/item/{id}" hint="Item to get, update and delete item records using <code>GET</code>,<code>PUT</code> and <code>DELETE</code> methods.">
	
	<!--- :: METHOD: GET :: --->

	<cffunction name="GET" access="public" hint="Return DATA of single Item's Details by ID" returntype="struct" output="false">
		<cfargument name="id"  	type="string" required="yes" hint="Items get by itemid">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />

		<cftry>

		    <cfquery datasource="#variables.datasource#" name="result.query" >
				SELECT 	 
					items.itemID
					,items.itemTitle
					,items.itemText
					,items.itemExcerpt
					,items.itemCreateDate
					,items.itemPublishDate
					,items.userID
					,lcase(items.itemSlug) AS 'itemSlug'
					,items.itemUpdateDate
					,items.imageID
					,CONCAT( images.imagePath, '/', images.imageName ) AS 'item_fullsize_image'
					,CONCAT( images.imagePath, '/', images.imageThumbFileName ) AS 'item_thumb_image'
					,CONCAT( images.imagePath, '/', images.imageFileNameHalf ) AS 'item_mini_image'
					,lcase(val_itemtype.itemTypeName) AS 'itemTypeName'
					,U.userFirstName AS 'authorFirstName'
					,U.userLastName AS 'authorLastName'
					,U.isInfluencer AS 'isInfluencer'
					,U.userName AS 'authorUserName'
					,U.userEmail AS 'authorEmail'
					,U.userAddressLine1 AS 'authorAddressLine1'
					,U.userAddressLine2 AS 'authorAddressLine2'
					,U.userAddressLine3 AS 'authorAddressLine3'
					,S.stateName AS 'authorStateName'
					,C.countryFullName AS 'authorCountryName'
					,U.userCity AS 'authorCityName'
		        	,CASE U.userGender	
						WHEN '0' THEN 'N/A'	
						WHEN 'M' THEN 'Male'
						WHEN 'F' THEN 'Female'
					END AS 'authorGenderName'
					,SP.sponsorID

		        	,U.userAbout AS 'authorAbout'
					,CONCAT( UI.imagePath, '/', UI.imageName ) AS 'author_fullsize_image'
					,CONCAT( UI.imagePath, '/', UI.imageThumbFileName ) AS 'author_thumb_image'
					,CONCAT( UI.imagePath, '/', UI.imageFileNameHalf ) AS 'author_mini_image'
					,( SELECT max( meta_value ) FROM users_meta WHERE meta_key LIKE '%user_total_followers%' AND userID=U.userID ) AS 'author_total_followers'
					,( SELECT max( meta_value ) FROM users_meta WHERE meta_key LIKE '%user_total_posts%' AND userID=U.userID ) AS 'author_total_posts'
					,( SELECT count(R.recipeID) from recipes R WHERE R.userID=U.userID ) AS 'TotalRecipes'
					
				FROM items
				LEFT JOIN images ON images.entityID = items.itemID AND images.entitytypeID = 1
				LEFT JOIN users U ON U.userID = items.UserID
				LEFT JOIN sponsors SP ON SP.userID = U.userID AND SP.active = 1
				INNER JOIN val_itemtype ON val_itemtype.itemTypeID = items.itemTypeID
				LEFT JOIN val_states S on S.stateID = U.userStateID
				LEFT JOIN val_countries C on C.countryID = U.userCountryID
				LEFT JOIN images UI on UI.entityID = items.UserID	AND UI.entitytypeID = 4

				WHERE items.active = 1
				AND items.itemIsPublished = 1
			 	AND items.ItemID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#" list="yes" separator=","> )
			 	AND
		        	 (
		                ( items.itemPublishDate <= DATE(NOW()) OR itemPublishDate IS NULL )
		                AND
		                ( items.itemExpireDate  >= DATE(NOW()) OR itemExpireDate IS NULL )
		         	)	 	
			</cfquery>
			
			<cfif result.query.recordCount EQ 0 >
				<cfset result.message = application.messages['item_get_found_error']/>
				<cfreturn representationOf(result).withStatus(404) />
			</cfif>
		
			<cfcatch>
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /item/{id}/GET", errorCatch = variables.cfcatch  )>	

			  	<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
			
		</cftry>


		<cfset result.userSocialDetails = []>

		<cfif len(result.query.userID) AND result.query.userID NEQ 0>
			
			<cfset local.userSocialDetails = application.accountObj.getUserSocialDetails(result.query.userID)>

			<cfif local.userSocialDetails.status EQ true>
				<cfset result.userSocialDetails = local.userSocialDetails.dataset>
			
			</cfif>

		</cfif>
		
		
		<cfset result.status  	= true />
		<cfset result.message = application.messages['item_get_found_success']/>

	  	<cfset local.tmp = logAction( actionID = 1015, extra = "method: /item/{id}/GET"  )>
		  
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<!--- Method :: PUT --->

	<cffunction name="PUT" access="public" output="false" hint="user can update their items using <code>PUT</code> method." auth="true">
		<cfargument name="itemTitle"        required="true"   type="string"   />
		<cfargument name="itemSlug"         required="false"  type="string"   />
		<cfargument name="itemExcerpt"      required="false"  type="string"   />
		<cfargument name="itemText"         required="false"  type="string"   />
		<cfargument name="itemTypeID"       required="false"  type="numeric"  />
		<cfargument name="imageID"          required="false"  type="numeric"  />
		<cfargument name="userID"           required="false"  type="numeric"  />
		<!---
		<cfargument name="itemUpdateDate"   required="false"  type="any"      />
		--->
		<cfargument name="itemIsPublished"  required="false"  type="numeric"  />
		<cfargument name="itemIsFeatured"   required="false"  type="numeric"  />
		<cfargument name="itemPublishDate"  required="false"  type="any"      />
		<cfargument name="itemExpireDate"   required="false"  type="any"      />
		<cfargument name="isAllowComment"   required="false"  type="numeric"  />
		<cfargument name="isCustomURL"      required="false"  type="numeric"  />
		<cfargument name="itemCustomURL"    required="false"  type="string"   />
		<cfargument name="active"           required="false"  type="numeric"  />
		<cfargument name="notViewedOnly"    required="false"  type="string"   />
		<cfargument name="auth_token" type="string" required="yes" hint="User authorization token (auth_token)">

		<cftry>
			
			<cfset var local.qry = "" />
			<cfset result['message'] = "">
			<cfset result['error'] = "">
			<cfset result['status'] = true>
			
			<cfquery name="local.qry" datasource="#variables.datasource#" result="isUpdated">
				UPDATE items
				SET itemID = itemID
					<cfif structKeyExists(arguments, "itemID")>
						itemID            = <cfqueryparam value="#arguments.itemID#"          cfsqltype="cf_sql_integer"    />					
					</cfif>
					<cfif structKeyExists(arguments, "itemSlug") AND len( arguments.itemSlug )>
						,itemSlug         = <cfqueryparam value="#arguments.itemSlug#"        cfsqltype="cf_sql_varchar"    />					
					</cfif>
					<cfif structKeyExists(arguments, "itemTitle") AND len( arguments.itemTitle )>
						,itemTitle        = <cfqueryparam value="#arguments.itemTitle#"       cfsqltype="cf_sql_varchar"    />					
					</cfif>
					<cfif structKeyExists(arguments, "itemExcerpt") AND len( arguments.itemExcerpt )>
						,itemExcerpt      = <cfqueryparam value="#arguments.itemExcerpt#"     cfsqltype="cf_sql_varchar"    />					
					</cfif>
					<cfif structKeyExists(arguments, "itemText") AND len( arguments.itemText )>
						,itemText         = <cfqueryparam value="#arguments.itemText#"        cfsqltype="cf_sql_varchar"    />					
					</cfif>
					<cfif structKeyExists(arguments, "itemTypeID")>
						,itemTypeID       = <cfqueryparam value="#arguments.itemTypeID#"      cfsqltype="cf_sql_integer"    />					
					</cfif>
					<cfif structKeyExists(arguments, "imageID")>
						,imageID          = <cfqueryparam value="#arguments.imageID#"         cfsqltype="cf_sql_integer"    />					
					</cfif>
					<cfif structKeyExists(arguments, "userID")>
						,userID           = <cfqueryparam value="#arguments.userID#"          cfsqltype="cf_sql_integer"    />					
					</cfif>				

					,itemUpdateDate   = <cfqueryparam value="#datetimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp"  />
					
					<cfif structKeyExists(arguments, "itemIsPublished")>
						,itemIsPublished  = <cfqueryparam value="#arguments.itemIsPublished#" cfsqltype="cf_sql_tinyint"    />					
					</cfif>
					<cfif structKeyExists(arguments, "itemIsFeatured")>
						,itemIsFeatured   = <cfqueryparam value="#arguments.itemIsFeatured#"  cfsqltype="cf_sql_tinyint"    />					
					</cfif>
					<cfif structKeyExists(arguments, "itemPublishDate") AND len( arguments.itemPublishDate )>
						,itemPublishDate  = <cfqueryparam value="#arguments.itemPublishDate#" cfsqltype="cf_sql_timestamp"  />					
					</cfif>
					<cfif structKeyExists(arguments, "itemExpireDate") AND len( arguments.itemExpireDate )>
						,itemExpireDate   = <cfqueryparam value="#arguments.itemExpireDate#"  cfsqltype="cf_sql_timestamp"  />					
					</cfif>
					<cfif structKeyExists(arguments, "isAllowComment")>
						,isAllowComment   = <cfqueryparam value="#arguments.isAllowComment#"  cfsqltype="cf_sql_tinyint"    />					
					</cfif>
					<cfif structKeyExists(arguments, "isCustomURL")>
						,isCustomURL      = <cfqueryparam value="#arguments.isCustomURL#"     cfsqltype="cf_sql_tinyint"    />					
					</cfif>
					<cfif structKeyExists(arguments, "itemCustomURL") AND len( arguments.itemCustomURL )>
						,itemCustomURL    = <cfqueryparam value="#arguments.itemCustomURL#"   cfsqltype="cf_sql_varchar"    />					
					</cfif>
					<cfif structKeyExists(arguments, "active")>
						,active           = <cfqueryparam value="#arguments.active#"          cfsqltype="cf_sql_tinyint"    />					
					</cfif>
					<cfif structKeyExists(arguments, "notViewedOnly")>
						,notViewedOnly    = <cfqueryparam value="#arguments.notViewedOnly#"   cfsqltype="cf_sql_bit"        />					
					</cfif>
					WHERE itemID 	  = <cfqueryparam value="#arguments.id#" 			  cfsqltype="cf_sql_numeric"  	/>
			</cfquery>

			<cfcatch>
				<!--- :: degrade gracefully :: --->
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset result.message = errorMessage( message = 'item_put_update_error', error = variables.cfcatch)>
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /item/{id}/PUT", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset statusCode = ( isUpdated.recordCount GT 0 ) ? 200 : 404 >

		<cfset result.message = statusCode EQ 200 ? application.messages['item_put_update_success'] : application.messages['item_put_update_error']/>

	  	<cfset local.tmp = logAction( actionID = 1006, extra = "method: /item/{id}/PUT"  )>

		<cfreturn representationOf(result).withStatus(statusCode) />
	</cffunction>


	<!--- Method :: DELETE --->

	<cffunction name="DELETE" access="public" output="false" hint="user can delete their items using <code>DELETE</code> method." auth="true">
		<cfargument name="id" type="numeric" required="yes" hint="ID of item." />
		<cfargument name="userID" type="numeric" required="yes" hint="userID">
		<cfargument name="auth_token" type="string" required="yes" hint="User authorization token (auth_token)">

		<cftry>
			
			<cfset var local.qry = "" />

			<cfquery name="local.qry" datasource="#variables.datasource#" result="isDeleted">
				DELETE FROM items WHERE itemID = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#" />
			</cfquery>

			<cfcatch>
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'item_put_update_error', error = variables.cfcatch)>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /item/{id}/DELETE", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset statusCode = ( isDeleted.recordCount GT 0 ) ? 200 : 404 >

		<cfset result.message = "success" />

	  	<cfset local.tmp = logAction( actionID = 1003, extra = "method: /item/{id}/DELETE"  )>

		<cfreturn noData().withStatus(statusCode) />
	</cffunction>

	<cffunction name="someInternalMethod" hint="you should not see this documentation...">
	</cffunction>

</cfcomponent>