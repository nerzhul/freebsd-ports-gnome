--- src/lib/net.c.orig	2019-12-04 17:29:36 UTC
+++ src/lib/net.c
@@ -1068,13 +1068,17 @@ enum net_hosterror_type net_get_hosterror_type(int err
 		int error;
 		enum net_hosterror_type type;
 	} error_map[] = {
+#ifdef EAI_ADDRFAMILY
 		{ EAI_ADDRFAMILY, NET_HOSTERROR_TYPE_NOT_FOUND },
+#endif
 		{ EAI_AGAIN, NET_HOSTERROR_TYPE_NAMESERVER },
 		{ EAI_BADFLAGS, NET_HOSTERROR_TYPE_INTERNAL_ERROR },
 		{ EAI_FAIL, NET_HOSTERROR_TYPE_NAMESERVER },
 		{ EAI_FAMILY, NET_HOSTERROR_TYPE_INTERNAL_ERROR },
 		{ EAI_MEMORY, NET_HOSTERROR_TYPE_INTERNAL_ERROR },
+#ifdef EAI_NODATA
 		{ EAI_NODATA, NET_HOSTERROR_TYPE_NOT_FOUND },
+#endif
 		{ EAI_NONAME, NET_HOSTERROR_TYPE_NOT_FOUND },
 		{ EAI_SERVICE, NET_HOSTERROR_TYPE_INTERNAL_ERROR },
 		{ EAI_SOCKTYPE, NET_HOSTERROR_TYPE_INTERNAL_ERROR },
