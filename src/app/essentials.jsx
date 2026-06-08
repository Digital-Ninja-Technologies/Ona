import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  ArrowLeft,
  DollarSign,
  FileText,
  Shield,
  Phone,
  Wifi,
  UtensilsCrossed,
  BookOpen,
  Package,
} from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { InstrumentSans_500Medium } from "@expo-google-fonts/instrument-sans";
import { useTheme } from "@/utils/theme/useTheme";

const essentialTools = [
  {
    id: "currency",
    title: "Currency Converter",
    description: "Convert between currencies",
    icon: DollarSign,
    screen: "/currency-converter",
  },
  {
    id: "visa",
    title: "Visa Requirements",
    description: "Check visa needs",
    icon: FileText,
    screen: "/visa-info",
  },
  {
    id: "safety",
    title: "Safety Tips",
    description: "Travel safety advice",
    icon: Shield,
    screen: "/safety-tips",
  },
  {
    id: "emergency",
    title: "Emergency Contacts",
    description: "Hospitals, police, embassies",
    icon: Phone,
    screen: "/emergency-contacts",
  },
  {
    id: "sim",
    title: "Local SIM Cards",
    description: "Stay connected",
    icon: Wifi,
    screen: "/sim-cards",
  },
  {
    id: "food",
    title: "Local Food Guide",
    description: "What to eat & where",
    icon: UtensilsCrossed,
    screen: "/food-guide",
  },
  {
    id: "etiquette",
    title: "Cultural Etiquette",
    description: "Local customs & manners",
    icon: BookOpen,
    screen: "/etiquette",
  },
  {
    id: "packing",
    title: "Packing Checklist",
    description: "Don't forget anything",
    icon: Package,
    screen: "/packing-checklist",
  },
];

export default function EssentialsScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
    InstrumentSans_500Medium,
  });

  if (!fontsLoaded) {
    return null;
  }

  const handleBackPress = () => {
    router.back();
  };

  const handleToolPress = (screen) => {
    // Navigate to all screens
    router.push(screen);
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background,
    },
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
    scrollView: {
      flex: 1,
    },
    contentContainer: {
      paddingHorizontal: 24,
      paddingTop: 24,
    },
    subtitle: {
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.textSecondary,
      lineHeight: 22,
      marginBottom: 24,
    },
    toolsGrid: {
      gap: 16,
    },
    toolCard: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: 20,
      flexDirection: "row",
      alignItems: "center",
      borderWidth: 1,
      borderColor: theme.border,
    },
    iconContainer: {
      width: 48,
      height: 48,
      borderRadius: 24,
      backgroundColor: "#FF6B9D",
      justifyContent: "center",
      alignItems: "center",
      marginRight: 16,
    },
    toolContent: {
      flex: 1,
    },
    toolTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 16,
      color: theme.text,
      marginBottom: 4,
    },
    toolDescription: {
      fontFamily: "Nunito_400Regular",
      fontSize: 13,
      color: theme.textSecondary,
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Travel Essentials</Text>
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
          Everything you need to know before and during your trip
        </Text>

        <View style={styles.toolsGrid}>
          {essentialTools.map((tool) => (
            <TouchableOpacity
              key={tool.id}
              style={styles.toolCard}
              onPress={() => handleToolPress(tool.screen)}
              activeOpacity={0.7}
            >
              <View style={styles.iconContainer}>
                <tool.icon size={24} color="#1A1A1A" />
              </View>

              <View style={styles.toolContent}>
                <Text style={styles.toolTitle}>{tool.title}</Text>
                <Text style={styles.toolDescription}>{tool.description}</Text>
              </View>
            </TouchableOpacity>
          ))}
        </View>
      </ScrollView>
    </View>
  );
}
