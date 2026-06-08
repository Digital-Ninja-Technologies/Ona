import React, { useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  ArrowLeft,
  ThumbsUp,
  ThumbsDown,
  Users,
  Handshake,
} from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";

const etiquetteCategories = [
  {
    id: "greetings",
    title: "Greetings & Gestures",
    icon: Handshake,
    color: "#FF6B9D",
    dos: [
      "Learn basic greetings in the local language",
      "Observe and mirror local greeting customs",
      "Smile - it's universal!",
      "Be aware of personal space preferences",
    ],
    donts: [
      "Don't assume handshakes are always appropriate",
      "Avoid overly enthusiastic gestures",
      "Don't point with fingers (use open hand)",
      "Be careful with thumbs up - offensive in some cultures",
    ],
  },
  {
    id: "dining",
    title: "Dining Customs",
    icon: Users,
    color: "#FF9500",
    dos: [
      "Wait to be seated in restaurants",
      "Try a bit of everything offered",
      "Keep both hands visible at table (not in lap)",
      "Finish your plate to show appreciation",
    ],
    donts: [
      "Don't start eating before others",
      "Avoid talking with mouth full",
      "Don't stick chopsticks upright in rice (Asian countries)",
      "Never refuse hospitality rudely",
    ],
  },
  {
    id: "dress",
    title: "Dress Code & Modesty",
    icon: ThumbsUp,
    color: "#34C759",
    dos: [
      "Dress modestly when visiting religious sites",
      "Cover shoulders and knees in conservative areas",
      "Remove shoes when entering homes (in many cultures)",
      "Check dress codes for restaurants/venues",
    ],
    donts: [
      "Don't wear revealing clothing in conservative countries",
      "Avoid overly casual beach wear in cities",
      "Don't wear shoes inside homes without permission",
      "Avoid offensive slogans or imagery on clothing",
    ],
  },
  {
    id: "social",
    title: "Social Interactions",
    icon: ThumbsDown,
    color: "#5856D6",
    dos: [
      "Be patient and polite always",
      "Ask before taking photos of people",
      "Learn about tipping customs",
      "Respect queuing culture",
    ],
    donts: [
      "Don't raise your voice or get angry publicly",
      "Avoid discussing sensitive topics (politics, religion)",
      "Don't make assumptions about customs",
      "Never disrespect local traditions or beliefs",
    ],
  },
];

export default function EtiquetteScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [expandedCategory, setExpandedCategory] = useState(null);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
  });

  if (!fontsLoaded) return null;

  const toggleCategory = (id) => {
    setExpandedCategory(expandedCategory === id ? null : id);
  };

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: theme.background },
    header: {
      flexDirection: "row",
      alignItems: "center",
      paddingHorizontal: 20,
      paddingBottom: 16,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    backButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: theme.surface,
      justifyContent: "center",
      alignItems: "center",
      marginRight: 12,
    },
    headerTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 20,
      color: theme.text,
    },
    scrollView: { flex: 1 },
    contentContainer: { paddingHorizontal: 24, paddingTop: 24 },
    subtitle: {
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.textSecondary,
      lineHeight: 22,
      marginBottom: 24,
    },
    categoryCard: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      marginBottom: 12,
      borderWidth: 1,
      borderColor: theme.border,
      overflow: "hidden",
    },
    categoryHeader: {
      flexDirection: "row",
      alignItems: "center",
      padding: 20,
    },
    iconContainer: {
      width: 48,
      height: 48,
      borderRadius: 24,
      justifyContent: "center",
      alignItems: "center",
      marginRight: 16,
    },
    categoryTitle: {
      flex: 1,
      fontFamily: "Nunito_600SemiBold",
      fontSize: 16,
      color: theme.text,
    },
    contentContainer2: {
      paddingHorizontal: 20,
      paddingBottom: 20,
    },
    sectionTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 15,
      color: theme.text,
      marginBottom: 12,
    },
    item: {
      flexDirection: "row",
      marginBottom: 10,
    },
    doIcon: {
      fontSize: 16,
      marginRight: 8,
      marginTop: 2,
    },
    itemText: {
      flex: 1,
      fontFamily: "Nunito_400Regular",
      fontSize: 14,
      color: theme.text,
      lineHeight: 20,
    },
    separator: {
      height: 16,
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => router.back()}
        >
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Cultural Etiquette</Text>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.subtitle}>
          Respect local customs and avoid cultural faux pas
        </Text>

        {etiquetteCategories.map((category) => (
          <View key={category.id} style={styles.categoryCard}>
            <TouchableOpacity
              style={styles.categoryHeader}
              onPress={() => toggleCategory(category.id)}
              activeOpacity={0.7}
            >
              <View
                style={[
                  styles.iconContainer,
                  { backgroundColor: category.color },
                ]}
              >
                <category.icon size={24} color="#1A1A1A" />
              </View>
              <Text style={styles.categoryTitle}>{category.title}</Text>
            </TouchableOpacity>

            {expandedCategory === category.id && (
              <View style={styles.contentContainer2}>
                <Text style={styles.sectionTitle}>✅ Do's</Text>
                {category.dos.map((item, index) => (
                  <View key={index} style={styles.item}>
                    <Text style={styles.doIcon}>•</Text>
                    <Text style={styles.itemText}>{item}</Text>
                  </View>
                ))}

                <View style={styles.separator} />

                <Text style={styles.sectionTitle}>❌ Don'ts</Text>
                {category.donts.map((item, index) => (
                  <View key={index} style={styles.item}>
                    <Text style={styles.doIcon}>•</Text>
                    <Text style={styles.itemText}>{item}</Text>
                  </View>
                ))}
              </View>
            )}
          </View>
        ))}
      </ScrollView>
    </View>
  );
}
