<cfcomponent extends="taffyAPI.base" taffy:uri="/widget/" hint="Using this widget can able to <code>Get</code> the blog's widget details by passing BlogID & styleID.">
	
	<cffunction name="GET" access="public" hint="Return widget Details of that blog." output="false">
	
		<cfargument name="blogID"  type="numeric" required="true" hint="Blog ID">
		<cfargument name="styleID" type="numeric" required="true" hint="Style ID">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />

		<cftry>

		    <cfhttp url="https://widget.yummienation.com/" method="get" result="local.widget">
				<cfhttpparam type="url" name="BlogID" value="#arguments.blogID#"/>
				<cfhttpparam type="url" name="StyleID" value="#arguments.styleID#"/>
			</cfhttp>

			<cfif local.widget.statusCode NEQ '200 OK' >
				
				<cfset result.status  	= false />
				<cfset result.message 	= application.messages['widget_get_found_error'] />
				<cfreturn representationOf(result).withStatus(404) />

			</cfif>

			<cfset result.widget = local.widget.fileContent />
		   
		  	<cfcatch>				
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /widget/GET", errorCatch = variables.cfcatch  )>	
			  
			  	<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		
	    </cftry>

	    <cfset result.status  	= true />
	    <cfset result.message = application.messages['widget_get_found_success'] />

	  	<cfset local.tmp = logAction( actionID = 201, extra = "method: /widget/GET"  )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	

</cfcomponent>