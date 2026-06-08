import { useLocalSearchParams, useRouter } from "expo-router";
import { useEffect } from "react";
import { Platform } from "react-native";
import { WebView } from "react-native-webview";
import useSubscription from "@/utils/use-subscription";

export default function Stripe() {
  const { checkoutUrl } = useLocalSearchParams();
  const router = useRouter();
  const { refetchSubscription } = useSubscription();

  useEffect(() => {
    if (Platform.OS === "web") {
      if (checkoutUrl) {
        const popup = window.open(checkoutUrl, "_blank", "popup");
        const checkClosed = setInterval(() => {
          try {
            if (
              popup.closed ||
              popup.location.href.includes(process.env.EXPO_PUBLIC_APP_URL)
            ) {
              clearInterval(checkClosed);
              popup.close();
              refetchSubscription().finally(router.back);
            }
          } catch (e) {}
        }, 1000);
      } else {
        router.back();
      }
    }
  }, [checkoutUrl, router]);

  const handleWebViewClose = () => {
    refetchSubscription().finally(router.back);
  };

  const handleShouldStartLoadWithRequest = (request) => {
    if (request.url.startsWith(process.env.EXPO_PUBLIC_APP_URL)) {
      handleWebViewClose();
      return false;
    }
    return true;
  };

  if (Platform.OS === "web") {
    return null;
  }

  return (
    <WebView
      source={{ uri: checkoutUrl }}
      style={{ flex: 1 }}
      onShouldStartLoadWithRequest={handleShouldStartLoadWithRequest}
    />
  );
}
