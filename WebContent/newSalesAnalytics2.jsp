<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="ucsd.shoppingApp.models.* , java.util.*" %>
<%@page import="java.sql.Connection, ucsd.shoppingApp.ConnectionManager, ucsd.shoppingApp.*"%>
 
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>Super Sales Analytics</title>
</head>
<body>
	<%@ page import="java.sql.*"%>
	<%@ page import="java.util.List" %>
	<%@ page import="java.util.ArrayList" %>
<%
 

	/* Keep track of the most recent run-values */


	if(session.getAttribute("roleName") != null) {
		 String role = session.getAttribute("roleName").toString();
		if("owner".equalsIgnoreCase(role) == true){ 
			/* Initialize and prep variables */
			Connection conn = null;
		
			Statement stmt; 
			Statement row_stmt;
			Statement filter_stmt; 
			Statement category_stmt; 
			Statement log_stmt;
			Statement pc_stmt;
			
			ResultSet rs = null;
			ResultSet row_rs = null;
			ResultSet filter_rs = null;
			ResultSet category_rs = null;
			ResultSet log_rs = null;
			
			String query = null;			
			String row_query = null;
			String filter_query = null;
			String category_query = "SELECT * FROM Category";
			String log_query = null;
			String pc_query = null;
			
			
			/* Connect to the database */
			try {
				Class.forName("org.postgresql.Driver");
			} catch (Exception e){
				System.out.println("Driver error");
			}
		    conn = DriverManager.getConnection("jdbc:postgresql://localhost/shoppingAppDB?" +"user=postgres&password=postgres");
			
			
		    /* Create the statements to be used */
		    stmt = conn.createStatement();
			category_stmt = conn.createStatement();
			row_stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
			filter_stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
			log_stmt = conn.createStatement(ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
			pc_stmt = conn.createStatement();
			
			/* Grab the option parameters for later use */
			String filter2 = "" + session.getAttribute("filter2"); 	
		 	
			/* Prepare the queries */
			
			/****************** All categories (default) ******************/
			if(filter2 == null || filter2.equals("All Categories") || filter2.equals("null") || filter2.equals("all")) {						
					log_query = "SELECT * "
							+ "FROM log l "
							+ "GROUP BY l.id, sid, pid";	
					
		}
			/****************** Category is chosen (filter applied) ******************/
			else{
				log_query = "SELECT * "
						+ "FROM log l "
						+ "WHERE l.cname = '" + filter2 + "'"
						+ " GROUP BY l.id, sid, pid";				
			}
			
			LinkedHashMap<String, Double> pm = new LinkedHashMap<String, Double>();
			LinkedHashMap<String, Double> sm = new LinkedHashMap<String, Double>();
			LinkedHashMap<String, Double> cm = new LinkedHashMap<String, Double>();
			HashMap<String, Double> productMap = new HashMap<String, Double>();
			HashMap<String, Double> stateMap = new HashMap<String, Double>();
			HashMap<String, Double> cellMap = new HashMap<String, Double>();
			
			
			long attributes_start = System.nanoTime();
			
			
			if(session.getAttribute("pm") == null || session.getAttribute("pm").equals("null")){
				productMap = (HashMap<String, Double>) session.getAttribute("productMap");
			}
			else{
				productMap = (HashMap<String, Double>) session.getAttribute("pm");
			}
			
			if(session.getAttribute("sm") == null || session.getAttribute("sm").equals("null")){
				stateMap = (HashMap<String, Double>) session.getAttribute("stateMap");
			}
			else{
				stateMap = (HashMap<String, Double>) session.getAttribute("sm");
			}
			
			if(session.getAttribute("cm") == null || session.getAttribute("cm").equals("null")){
				cellMap = (HashMap<String, Double>) session.getAttribute("cellMap");
			}
			else{
				cellMap = (HashMap<String, Double>) session.getAttribute("cm");
			}
			
						
			long attributes_end = System.nanoTime();
			
			
			long queries_start = System.nanoTime();
			
			/* Execute the queries */
			log_rs = log_stmt.executeQuery(log_query);
			%>

<%
			LinkedHashMap<String, Double> logMap = new LinkedHashMap<String, Double>();
			while(log_rs.next()){
				String key = "" + log_rs.getString("sname") + " " + log_rs.getString("pname");
				logMap.put(key, log_rs.getDouble("total"));			
			}
		
			log_rs.beforeFirst();
 
			long queries_end = System.nanoTime();
			
			long table_start = System.nanoTime();
			
			
			List<String> productList2 = new ArrayList<String>(productMap.keySet());
			List<String> pl2 = new ArrayList<String>();
			List<String> sl2 = new ArrayList<String>(stateMap.keySet());
			Set<String> keys2 = productMap.keySet();
			LinkedHashMap<String, Double> pm2 = new LinkedHashMap<String, Double>();
	        for(String k:keys2){
	        	pl2.add(k);
	        	int increase = 0;

				for(String i:stateMap.keySet()){
					if(logMap.get(i + " " + k) != null){
						increase += logMap.get(i + " " + k);
					}
				}
				
				if(increase == 0){
					pm2.put(k, productMap.get(k));		
				}
				else{
					pm2.put(k, productMap.get(k)+increase);					
				} 					
			} 
			
			
			/* Take the top-50 of the most recent run and compare it to the top-50 of the most recent refresh */
			HashMap<String, Double> runMap = (HashMap<String, Double>) session.getAttribute("productMap");
			List<String> kickedEntries = new ArrayList<String>();
			List<String> newEntries = new ArrayList<String>(); 
			
			List<String> runKeys = new ArrayList<String>(runMap.keySet());
			List<String> refreshKeys = new ArrayList<String>(pm2.keySet());
				
			HashMap<String, Double> refreshMap = pm2;
			
			Collections.sort(refreshKeys, new Comparator<String>() {
			    @Override
			    public int compare(String s1, String s2) { /* return refreshMap.get(s2) - refreshMap.get(s1); } */
			    	if(refreshMap.get(s2) > refreshMap.get(s1)){
			    		return 1;
			    	}
			    	else if(refreshMap.get(s1) > refreshMap.get(s2)){
			    		return -1;
			    	}
			    	else{
			    		return 0;
			    	}
				}
			});
			
			List<String> currTop50 = new ArrayList<String>();
			List<String> newTop50 = new ArrayList<String>();
			List<String> tempList = new ArrayList<String>();
			for(int i = 0; i < 50; i++){
				currTop50.add(runKeys.get(i));
				newTop50.add(refreshKeys.get(i));
				tempList.add(runKeys.get(i));
			}
			
			currTop50.removeAll(newTop50);
			newTop50.removeAll(tempList);
			
			System.out.println("Kicked entries: " + currTop50);
			System.out.println("New entries: " + newTop50);				

			
			%>
			<style>
			.purple { 
			    background-color: #D213EF;
			}
			</style>

				<%if(newTop50.size()>0){ %>
					<tr>These are the newest entries to the top 50: <%=newTop50 %></tr>
				<%}%>
				 <!-- TABLE DISPLAY  -->
				<div id="runTable">
				<table border="1">
				<tr>
					<th>States</th>
			<% 	
				List<String> productList = new ArrayList<String>(productMap.keySet());
				List<String> pl = new ArrayList<String>();
				List<String> sl = new ArrayList<String>(stateMap.keySet());
				Set<String> keys = productMap.keySet();
				int tempCounter = 0;
				String style = null;
		        for(String k:keys){
	
					if(currTop50.contains(k)){
						style = "purple";
					}
					else{
						style = "black";
					}
		        	pl.add(k);
		        	int increase = 0;

					for(String i:stateMap.keySet()){
						if(logMap.get(i + " " + k) != null){
							increase += logMap.get(i + " " + k);
						}
					}
					
						if(increase == 0){
							if(tempCounter < 50){
								%><td class=<%=style%>><%=k %> ($<%=productMap.get(k)%>) </td> <%
							}
							pm.put(k, productMap.get(k));
						
						}
						else{
							if(tempCounter < 50){
								%><td class=<%=style%> style="color:red"><%=k %> ($<%=productMap.get(k)+increase%>) </td> <%
							}
							pm.put(k, productMap.get(k)+increase);
							
						}
					
					tempCounter++;
					%>
						
					
					<% 					
				} %>
				</tr>
	
				<tr> <%
				int j = 0;
				String prod = null;
				int counter = 0;
				List<Double> cells = new ArrayList<Double>(cellMap.values());
				Set<String> state_keys = stateMap.keySet();
				
				
		        for(String s:state_keys){
		        	int increase = 0;
					%> <tr> <%
					for(int i = 0; i < pl.size(); i++){
						String prod2 = pl.get(i);
						if(logMap.get(s + " " + prod2) != null){
							increase += logMap.get(s + " " + prod2);
						}
					}
					if(increase == 0){
						%><td><%=s %> ($<%=stateMap.get(s)%>) </td> <%
						sm.put(s, stateMap.get(s));
					}
					else{
						%><td style="color:red"><%=s %> ($<%=stateMap.get(s)+increase%>) </td> <%
						sm.put(s, stateMap.get(s)+increase);
					}
					
		        	for(int i = j*50, k = 0; i < (j*50)+50; i++, k++){
		        		prod = pl.get(k);
		        		if(currTop50.contains(prod)){
							style = "purple";
						}
						else{
							style = "black";
						}
		        		if(logMap.get(s + " " + prod) != null){
		        			counter++;
		        			%><td class=<%=style%> style="color:red"><%=cells.get(i) + logMap.get(s + " " + prod)%></td><%
		        			cm.put(s + " " + prod, cells.get(i) + logMap.get(s + " " + prod));
		        		}
		        		else{
		        			%><td class=<%=style%>><%=cells.get(i) %></td><%
		        			cm.put(s + " " + prod, cells.get(i));
		        		}
		        	}
					j++;
				
					%> </tr>
			<% } %> 
			</table> 
			</div><%

			
			/*
				
			if(session.getAttribute("currTop50") ==  null){
			List<String> currTop50 = new ArrayList<String>();
			}
			else{
				List<String> currTop50 = session.getAttribute("currTop50");
			}
			
			if(session.getAttribute("newTop50") == null){
				List<String> newTop50 = new ArrayList<String>();
			}
			else{
				List<String> newTop50 = session.getAttribute("newTop50");
			}
			
			if(session.getAttribute("tempList") == null){
				List<String> tempList = new ArrayList<String>();
			}
			else{
				List<String> tempList = session.getAttribute("tempList");
			}
			
			*/				
			
					
			long table_end = System.nanoTime();
			session.setAttribute("pm", pm);
			session.setAttribute("sm", sm);
			session.setAttribute("cm", cm);	
			
			long updates_start = System.nanoTime();
			
				
			pc_query = "UPDATE product_sales "
					+ "SET total = product_sales.total + log.total "
					+ "FROM log "
					+ "WHERE product_name = log.pname";
			pc_stmt.executeUpdate(pc_query);
			
			pc_query = "INSERT INTO state_sales(total, state_id, state_name, category_id, category_name)( "
					+ "SELECT total, sid, sname, cid, cname FROM log)";
			pc_stmt.executeUpdate(pc_query);
			
			pc_query = "INSERT INTO sales(state_id, product_id, total, product_name, state_name, category_id, category_name)( "
					+ "SELECT sid, pid, total, pname, sname, cid, cname FROM log)";
			pc_stmt.executeUpdate(pc_query); 
		
			long updates_end = System.nanoTime();
			pc_query = "delete from log";
			pc_stmt.executeUpdate(pc_query);
			long deletes_end = System.nanoTime();
			
			
			long att_time = (attributes_end - attributes_start)/1000000;		
			long query_time = (queries_end - queries_start)/1000000;
			long table_time = (table_end - table_start)/1000000;
			long update_time = (updates_end - updates_start)/1000000;
			long delete_time = (deletes_end - updates_end)/1000000;
			
			System.out.println("Attributes runtime: " + att_time + " ms");
			System.out.println("Query runtime: " + query_time + " ms");
			System.out.println("Table runtime: " + table_time + " ms");
			System.out.println("Update runtime: " + update_time + " ms");
			System.out.println("Delete runtime: " + delete_time + " ms\n");
			
			%>
	 <% } 
		else { %>
			<h3>This page is available to owners only</h3>
		<%
		}  
	}
	else { %>
			<h3>Please <a href = "./login.jsp">login</a> before viewing the page</h3>
	<%} %>
</body>
</html>