<cfcomponent extends="taffyAPI.base" displayname="influencerMeta" hint="Used to INSERT, SELECT, DELETE operations for the influencerMeta table.">
	
	<cffunction name="getInfluencerMeta" returntype="Query" access="public" >

		<cfargument name="meta_key" type="string" required="true">	
		<cfargument name="userID" type="numeric" required="true">

		<cfquery name="local.query" datasource="#variables.datasource#">

			SELECT meta_key,meta_value FROM influencers_meta 
			WHERE meta_key IN ( 
								<cfqueryparam value="#arguments.meta_key#" cfsqltype="cf_sql_varchar" list="true">	
							)
			AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">

		</cfquery>

		<cfreturn local.query>

	</cffunction>

	<cffunction name="insertInfluencerMeta" access="public" output="false" hint="used to insert the influencers_meta details">
		
		<cfargument name="meta_key" 	type="string" 	required="true">
		<cfargument name="meta_value" 	type="string" 	required="true">
		<cfargument name="userID" 		type="numeric" 	required="true">	


		<cfquery name="local.query" datasource="#variables.datasource#" >

			INSERT INTO influencers_meta (userID,meta_key,meta_value) VALUES
				(
					<cfqueryparam value="#arguments.userID#"   		cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#arguments.meta_key#" 		cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#arguments.meta_value#" 	cfsqltype="cf_sql_varchar">
				) 

		</cfquery>

		<cfreturn />

	</cffunction>

	<cffunction name="deleteInfluencerMeta" access="public" output="false" hint="used to delete the influencer_meta table details.">

		<cfargument name="metacolumns" type="string" required="true">
		<cfargument name="userID" type="numeric" required="true">

		<cfquery name="local.delete" datasource="#variables.datasource#" result="qry">

			DELETE FROM influencers_meta 
			    WHERE meta_key IN ( 
									<cfqueryparam value="#arguments.metacolumns#" cfsqltype="cf_sql_varchar" list="true">
								) 
				AND userID = <cfqueryparam value="#arguments.userID#">
		</cfquery>

		<cfreturn />

	</cffunction>

</cfcomponent>