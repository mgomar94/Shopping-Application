<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
		<title>Similar Products</title>
	</head>
	<body>
	<h1>Similar Products</h1>
	<%@ page import="java.sql.*"%>
	<%@ page import="java.util.List" %>
	<%@ page import="java.util.ArrayList" %>
	
	
	<table cellspacing = "5px"><tr>
		<td valign="top"><jsp:include page="menu.jsp"></jsp:include></td>
		<td>
		<h3> Click on any of the links on the left to navigate away from this page.</h3></td>
		
		</tr>
	</table>
	
	
	<% 
	
	
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    ResultSet rs2 = null;
    long query_start = 0;
    long query_end = 0;
 
    try {
    // Registering Postgresql JDBC driver with the DriverManager
    Class.forName("org.postgresql.Driver");
 
    // Open a connection to the database using DriverManager
    conn = DriverManager.getConnection("jdbc:postgresql://localhost/shoppingAppDB?" +"user=postgres&password=postgres");
    conn.setAutoCommit(false);
 
    
    Statement statement = conn.createStatement();
    rs = statement.executeQuery("select count(*) as cnt from product");
	//conn.commit();
	int num_prods = 0;
    rs.next();
    num_prods = rs.getInt("cnt");
/* 
    int cont = 0; 
    float A_cust_price = 0,
    	  B_cust_price = 0,
    	  cos_sim = 0,
    	  norm_cos_sim = 0,
    	  A_tot_price = 0,
    	  B_tot_price = 0;  */
    
    %><table border="3">
    <tr>
   		<td>Product A Name</td>
	<!--<td>Product A ID</td> -->
	    <td>Product B Name</td>
	  <!-- <td>Product B ID</td> -->  
	    <td>Similarity</td>
    </tr>
   <%/* for(int i = 1; i <= num_prods; i++){
    	for(int j = i+1; j <= num_prods; j++){
    		pstmt = conn.prepareStatement("INSERT INTO cos_sim (productA_name,"+ 
    		"A_id, productB_name, B_id, cos_similarity) VALUES (?, ?, ?, ?, ?)");
    	    rs = statement.executeQuery("select id, product_name from product"); */
    	//for(int i = 1; i <= num_prods; i++){
    		
    		/* Execute the query */
			query_start = System.nanoTime();
    		rs = statement.executeQuery(
    				"WITH SALES AS (select pr.product_name, pc.product_id,sc.person_id,sum(pc.price*pc.quantity) as amount " +
    			 	"from products_in_cart pc " +
    			 	"inner join shopping_cart sc on (sc.id = pc.cart_id and sc.is_purchased = true) " +
    			 	"inner join product pr on (pr.id = pc.product_id) " +
    			 	"group by pc.product_id,sc.person_id,pr.product_name), " +
    			 	
    				"DENOM AS (" +
    				"SELECT product_id, SUM(amount) as denom_sums " +
    				"FROM SALES " +
    				"GROUP BY product_id) " +
    				
    			"SELECT s1.product_name as aname, s2.product_name as bname, s1.product_id as aid, s2.product_id as bid, (SUM (s1.amount*s2.amount)/(d1.denom_sums * d2.denom_sums)) as val " +
    			"FROM SALES s1 JOIN SALES s2 ON (s1.product_id < s2.product_id), DENOM d1, DENOM d2 " +
    			"WHERE s1.person_id = s2.person_id AND d1.product_id = s1.product_id AND d2.product_id = s2.product_id " +
    			"GROUP BY (s1.product_id, s2.product_id, s1.product_name, s2.product_name, d1.denom_sums, d2.denom_sums) " +
    			"ORDER BY val desc LIMIT 100;");

    		query_end = System.nanoTime();
    		
    		while(rs.next()){
    			
    		    %>			<tr>
    		    				<td>
    		    					<%=rs.getString("aname") %>
    		    				</td>
    		    				
    		    			<%-- 	<td>
    		    					<%=rs.getInt("aid") %>
    		    				</td> --%>
  				
    		    				<td>
    		    					<%=rs.getString("bname")  %>
    		    				</td>
    		    				
    		    	<%-- 			<td>
    		    					<%=rs.getInt("bid") %>
    		    				</td> --%>

    		    				<td>
    		    					<%=rs.getFloat("val") %>
    		    				</td>
    		    			</tr>
    		    				<%} %>       
 
 
<% //}

    	    
long query_time = (query_start - query_end)/(-1000000);
System.out.println("Cos_Sim Query runtime: " + query_time + " ms");

%>
    	 			
    			<%//Add the next two products into a new row. Pairs are (0,1), (0,2)...(0,n)..(1,2)...(1,n)..(n-1,n)
    			/*
    			if(rs.getInt("id") == i){
    				pstmt.setString(1, rs.getString("product_name"));
    				pstmt.setInt(2, rs.getInt("id"));
    				cont++;
    			}
    			if(rs.getInt("id") == j){
    				pstmt.setString(3, rs.getString("product_name"));
    				pstmt.setInt(4, rs.getInt("id"));
    				cont++;
    			}
    			
    			if(cont == 2){
	    			//find customer totals for specific product and get the cosine similarity
	    			for(int k = 1; k <= num_custs; k++){
	    		        rs2 = statement.executeQuery("select pic.price, SUM(pic.quantity) " + 
	    		        		"from products_in_cart pic, shopping_cart sc, person p " + 
	    		            	"where (pic.product_id = " + i + " or pic.product_id = " + j +
	    		            	") and pic.cart_id = sc.id and sc.person_id = p.id and p.id = " + k +
	    		            	" group by pic.price");
	    		       if(rs2.next()){
	    		       		A_cust_price = rs2.getFloat("price") * rs2.getInt("sum");
	    		       }
	    		        
	    		       if(rs2.next()){
	    		        	B_cust_price = rs2.getFloat("price") * rs2.getInt("sum");
	    		       }
	    		       cos_sim += (A_cust_price * B_cust_price);
	    		       A_cust_price = 0;
	    		       B_cust_price = 0;
	    			}
	    			
	    			select * as cosinesimilarity
	    			//normalize the cosine similairty
			        rs2 = statement.executeQuery("with norms as (select pic.price, SUM(pic.quantity) " + 
			        		"from products_in_cart pic, shopping_cart sc, person p " + 
			            	"where (pic.product_id = " + i + " or pic.product_id = " + j +
			            	") and pic.cart_id = sc.id and sc.person_id = p.id group by pic.price");
			        if(rs2.next()){
			        	A_tot_price = rs2.getFloat("price") * rs2.getInt("sum");
			        }
 
			        if(rs2.next()){
			        	B_tot_price = rs2.getFloat("price") * rs2.getInt("sum");
			        }
			        norm_cos_sim = cos_sim / (A_tot_price * B_tot_price);
			        
			        pstmt.setFloat(5, norm_cos_sim);
			        cont = 0;
			        break;
    			}
    			
    			
    		}
    		//pstmt.setInt(5, 1);
    		int rowCount = pstmt.executeUpdate();
            conn.commit();
            */
            
	   /*      rs = statement.executeQuery("select pic.price, SUM(pic.quantity) " + 
	        		"from products_in_cart pic, shopping_cart sc, person p " + 
	            	"where pic.product_id = 3 and pic.cart_id = sc.id " + 
	            	"and sc.person_id = p.id group by pic.price");
    		 */
    	%>	 
    	
            </table>
 		<%
/*
    	}
    }
    
*/   
    
    
    
    %>
     <%
                // Close the ResultSet
                rs.close();
 
                // Close the Statement
                //statement.close();
 
                // Close the Connection
                conn.close();
            } catch (SQLException e) {
 
                // Wrap the SQL exception in a runtime exception to propagate
                // it upwards
                
                throw new RuntimeException(e);
            }
            finally {
                // Release resources in a finally block in reverse-order of
                // their creation
 
                if (rs != null) {
                    try {
                        rs.close();
                    } catch (SQLException e) { } // Ignore
                    rs = null;
                }
                if (pstmt != null) {
                    try {
                        pstmt.close();
                    } catch (SQLException e) { } // Ignore
                    pstmt = null;
                }
                if (conn != null) {
                    try {
                        conn.close();
                    } catch (SQLException e) { } // Ignore
                    conn = null;
                }
            	}
            
            
            	
            
            %>
	</body>
</html>