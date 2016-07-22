<?xml version="1.0"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:atilf="http://www.atilf.fr" xmlns:functx="http://www.functx.com" exclude-result-prefixes="xs xsl atilf functx">

  <!-- marquage de matching de regex dans un arbre xml.... -->

  <xsl:param name="motif">ab</xsl:param>

  
 

  <xsl:function name="atilf:getMatches" as="xs:integer*">
    <xsl:param name="arg" as="xs:string?"/>
    <xsl:param name="pattern" as="xs:string"/>
    <!-- not matches nous donne la longueur des `non matches' situés entre les matches...-->
    <xsl:variable name="notMatchLengths" select="for $i in tokenize($arg, $pattern)
						 return string-length($i)"/>
    <!-- matchLengths = longueur des matches -->
    <xsl:variable name="matchLengths" as="xs:integer*"> 
      <xsl:analyze-string select="$arg" regex="{$pattern}">
	<xsl:matching-substring>
	  <xsl:value-of select="string-length(.)"/>
	</xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    
    <!-- our result : indexOfMatch lengthOfMatch indexOfMatch lengthOfMatch, etc... -->
  
    <xsl:for-each select="$matchLengths">
      <xsl:variable name="i" select="position()"/>
      <xsl:value-of select="sum(for $j in 1 to $i return $notMatchLengths[$j])+1+sum(for $j in 1 to $i -1 return $matchLengths[$i])"/>
      <xsl:value-of select="."/>
    </xsl:for-each>
  
                                                  
    </xsl:function>


  
  <xsl:function name="atilf:marquerMatchNoeud">
    <xsl:param name="nd"/>
    <xsl:param name="debutMatch"/>
    <xsl:param name="lgMatch"/>
    <xsl:param name="key"/>
    
    <!-- <xsl:message>marquerMatchNoeud(<xsl:copy-of select="$nd"/>, <xsl:value-of select="$debutMatch"/>, <xsl:value-of select="$lgMatch"/>)&#x0a;</xsl:message> -->
    <xsl:choose>
      <xsl:when test="$nd/self::text()">
	<xsl:value-of select="substring($nd, 1, $debutMatch -1)"/>
	<span to="{concat('#a_', generate-id($nd))}" xml:id="{concat('s_',generate-id($nd))}" key="{$key}"/>
	<xsl:value-of select="substring($nd, $debutMatch, $lgMatch)"/>
	<anchor xml:id="{concat('a_', generate-id($nd))}"/>
	<xsl:value-of select="substring($nd, $debutMatch+$lgMatch)"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:for-each select="$nd">
	  <xsl:copy>
	    <xsl:for-each select="@*">
	      <xsl:copy/>
	    </xsl:for-each>
	    <xsl:sequence select="atilf:marqueMatchSeqNoeuds($nd/node(), $debutMatch, $lgMatch, $key)"/>
	  </xsl:copy>
	</xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="atilf:marqueMatchSeqNoeuds">
    <xsl:param name="seqNds"/>
    <xsl:param name="debutMatch"/>
    <xsl:param name="lgMatch"/>
    <xsl:param name="key"/>
    
    <!-- <xsl:message><xsl:text>atilf:marqueMatchSeqNoeuds([</xsl:text>
    <xsl:for-each select="$seqNds">
      <xsl:copy-of select="."/>
      <xsl:if test="not(position() = last())">
	<xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:text>], </xsl:text><xsl:value-of select="$debutMatch"/><xsl:text>, </xsl:text>
    <xsl:value-of select="$lgMatch"/><xsl:text>)&#x0a;</xsl:text>
    </xsl:message> -->
    <!-- on veut connaître la taille du premier élément de la sequence -->
    <xsl:variable name="contenuPrem">
      <xsl:value-of select="$seqNds[1]"/>
    </xsl:variable>
    <xsl:variable name="lgPrem" select="string-length($contenuPrem)"/>
    
    <xsl:choose>

      <!-- est-ce que debutMatch est dedans ? -->
      <xsl:when test="$debutMatch &lt;= $lgPrem">
	<!-- <xsl:message>Début dans premier</xsl:message>-->
	<xsl:choose>

	  <!-- est-ce que la fin est aussi dedans ? -->
	  <xsl:when test="$debutMatch+$lgMatch -1 &lt;= $lgPrem">
	    <!-- <xsl:message>fin dans premier</xsl:message>-->
	    <xsl:sequence select="atilf:marquerMatchNoeud($seqNds[1], $debutMatch, $lgMatch, $key)"/>
	    <xsl:sequence select="$seqNds[position() &gt; 1]"/>
	  </xsl:when>
	  <xsl:otherwise>
	    <!-- <xsl:message>fin pas dans premier</xsl:message> -->
	    <!-- on insère ce qu'on peut dans le premier noeud et on continue... -->
	    <xsl:sequence select="atilf:marquerMatchNoeud($seqNds[1], $debutMatch, $lgPrem -$debutMatch +1, $key)"/>
	    <xsl:sequence select="atilf:marqueMatchSeqNoeuds($seqNds[position() &gt; 1], 1, $lgMatch -$lgPrem, $key)"/>
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:when>

      <!-- le debutMatch n'est pas dans le premier noeud.-->
      <xsl:otherwise>
	<!-- on avance d'un cran... -->
	<xsl:sequence select="$seqNds[1]"/>
	<xsl:sequence select="atilf:marqueMatchSeqNoeuds($seqNds[position() &gt; 1], $debutMatch -$lgPrem, $lgMatch, $key)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="atilf:markSomeMatches">
    <xsl:param name="nd" as="node()"/>
    <xsl:param name="matches" as="xs:integer*"/>
    <xsl:param name="key"/>
    
    <xsl:choose>
      <xsl:when test="count($matches) = 0">
	<xsl:sequence select="$nd"/>
      </xsl:when>
      <xsl:otherwise>
	<xsl:copy-of select="atilf:markSomeMatches(atilf:marquerMatchNoeud($nd, $matches[1], $matches[2], $key),
			     $matches[position() &gt; 2], $key)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="atilf:marquerRegex">
    <xsl:param name="node"/>
    <xsl:param name="pattern"/>
    <xsl:param name="key"/>
    
    <xsl:variable name="contenu">
      <xsl:value-of select="$node"/>
    </xsl:variable>
    <xsl:variable name="matches" select="atilf:getMatches($contenu, $pattern)"/>

    <!-- <xsl:message>debut : <xsl:value-of select="$iDeb"/> longueur : <xsl:value-of select="$lgMatch"/></xsl:message> -->
    
    <xsl:copy-of select="atilf:markSomeMatches($node, $matches, $key)"/>
  </xsl:function>

  
  <xsl:template match="/">
    <!-- <xsl:copy-of select="atilf:marquerRegex(r, $motif, 'toto')"/> -->
    <xsl:variable name="rc">
      <xsl:value-of select="r"/>
    </xsl:variable>
    <!-- <xsl:copy-of select="atilf:getMatches($rc, $motif)"/> -->
    <xsl:copy-of select="atilf:marquerRegex(r, $motif, 'toto')"/>
  </xsl:template>
</xsl:stylesheet>